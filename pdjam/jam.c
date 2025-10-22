#include "m_pd.h"
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <string.h>

static t_class *jam_class;

typedef struct _jam {
    t_object x_obj;
    lua_State *L;
    t_outlet *msg_out;     // left outlet: musical messages
    t_outlet *info_out;    // right outlet: info/debug
    t_float tpb;           // ticks per beat
    t_float bpm;           // beats per minute
    long tc;               // tick counter
} t_jam;

// Lua C function to implement io.playNote()
static int l_playNote(lua_State *L) {
    // Get the jam object from registry
    lua_getfield(L, LUA_REGISTRYINDEX, "pd_jam_obj");
    t_jam *x = (t_jam *)lua_touserdata(L, -1);
    lua_pop(L, 1);
    
    // Get arguments: note, velocity, duration, channel
    int note = luaL_checkinteger(L, 1);
    int velocity = luaL_checkinteger(L, 2);
    int duration = luaL_checkinteger(L, 3);
    int channel = luaL_optinteger(L, 4, 1);
    
    // Create and send PD message: [note 60 80 500 1(
    t_atom argv[5];
    SETSYMBOL(&argv[0], gensym("note"));
    SETFLOAT(&argv[1], (t_float)note);
    SETFLOAT(&argv[2], (t_float)velocity);
    SETFLOAT(&argv[3], (t_float)duration);
    SETFLOAT(&argv[4], (t_float)channel);
    outlet_list(x->msg_out, &s_list, 5, argv);
    
    return 0;
}

// Lua C function to implement io.sendCC()
static int l_sendCC(lua_State *L) {
    lua_getfield(L, LUA_REGISTRYINDEX, "pd_jam_obj");
    t_jam *x = (t_jam *)lua_touserdata(L, -1);
    lua_pop(L, 1);
    
    int controller = luaL_checkinteger(L, 1);
    int value = luaL_checkinteger(L, 2);
    int channel = luaL_optinteger(L, 3, 1);
    
    // Create and send PD message: [cc 7 64 1(
    t_atom argv[4];
    SETSYMBOL(&argv[0], gensym("cc"));
    SETFLOAT(&argv[1], (t_float)controller);
    SETFLOAT(&argv[2], (t_float)value);
    SETFLOAT(&argv[3], (t_float)channel);
    outlet_list(x->msg_out, &s_list, 4, argv);
    
    return 0;
}

// Lua C function to redirect print() to info outlet
static int l_print(lua_State *L) {
    lua_getfield(L, LUA_REGISTRYINDEX, "pd_jam_obj");
    t_jam *x = (t_jam *)lua_touserdata(L, -1);
    lua_pop(L, 1);
    
    // Build string from all arguments
    int n = lua_gettop(L);
    luaL_Buffer b;
    luaL_buffinit(L, &b);
    
    for (int i = 1; i <= n; i++) {
        if (i > 1) luaL_addstring(&b, "\t");
        
        if (lua_isstring(L, i)) {
            luaL_addvalue(&b);
        } else {
            // Convert to string
            lua_pushvalue(L, i);
            const char *s = lua_tostring(L, -1);
            if (s) {
                luaL_addstring(&b, s);
            }
            lua_pop(L, 1);
        }
    }
    
    luaL_pushresult(&b);
    const char *msg = lua_tostring(L, -1);
    
    // Send to info outlet
    outlet_symbol(x->info_out, gensym(msg));
    
    return 0;
}

// Lua C function to implement io.on()
static int l_on(lua_State *L) {
    lua_getfield(L, LUA_REGISTRYINDEX, "pd_jam_obj");
    t_jam *x = (t_jam *)lua_touserdata(L, -1);
    lua_pop(L, 1);
    
    double interval = luaL_optnumber(L, 1, 1.0);
    double offset = luaL_optnumber(L, 2, 0.0);
    
    long tc = x->tc - (long)(offset * x->tpb);
    if (tc < 0) {
        lua_pushboolean(L, 0);
        return 1;
    }
    
    double ticks_per_interval = x->tpb * interval;
    long expected_intervals = (long)(tc / ticks_per_interval);
    long interval_start_tick = (long)(expected_intervals * ticks_per_interval + 0.5);
    
    lua_pushboolean(L, tc == interval_start_tick);
    return 1;
}

// Lua C function to implement io.dur()
static int l_dur(lua_State *L) {
    lua_getfield(L, LUA_REGISTRYINDEX, "pd_jam_obj");
    t_jam *x = (t_jam *)lua_touserdata(L, -1);
    lua_pop(L, 1);
    
    double a = luaL_optnumber(L, 1, 1.0);
    double b = luaL_optnumber(L, 2, 1.0);
    
    long result = (long)((x->tpb * a) / b);
    lua_pushinteger(L, result);
    return 1;
}

// Initialize the io table in Lua
static void init_io(t_jam *x) {
    lua_State *L = x->L;
    
    // Create io table
    lua_newtable(L);
    
    // Set properties
    lua_pushnumber(L, x->tpb);
    lua_setfield(L, -2, "tpb");
    
    lua_pushnumber(L, x->bpm);
    lua_setfield(L, -2, "bpm");
    
    lua_pushinteger(L, x->tc);
    lua_setfield(L, -2, "tc");
    
    lua_pushinteger(L, 1);
    lua_setfield(L, -2, "ch");
    
    // Register C functions
    lua_pushcfunction(L, l_playNote);
    lua_setfield(L, -2, "playNote");
    
    lua_pushcfunction(L, l_sendCC);
    lua_setfield(L, -2, "sendCC");
    
    lua_pushcfunction(L, l_on);
    lua_setfield(L, -2, "on");
    
    lua_pushcfunction(L, l_dur);
    lua_setfield(L, -2, "dur");
    
    // Store io as global
    lua_setglobal(L, "io");
    
    // Override global print to use our outlet
    lua_pushcfunction(L, l_print);
    lua_setglobal(L, "print");
}

// Update io values before each tick
static void update_io(t_jam *x) {
    lua_State *L = x->L;
    
    lua_getglobal(L, "io");
    if (lua_istable(L, -1)) {
        lua_pushinteger(L, x->tc);
        lua_setfield(L, -2, "tc");
    }
    lua_pop(L, 1);
}

// Load and initialize a jam file
static int load_jam(t_jam *x, t_symbol *s) {
    lua_State *L = x->L;
    
    // Load the jam file
    if (luaL_dofile(L, s->s_name) != LUA_OK) {
        pd_error(x, "jam: error loading %s: %s", 
                 s->s_name, lua_tostring(L, -1));
        lua_pop(L, 1);
        return -1;
    }
    
    // The jam should return a table
    if (!lua_istable(L, -1)) {
        pd_error(x, "jam: %s did not return a table", s->s_name);
        lua_pop(L, 1);
        return -1;
    }
    
    // Store the jam table as global "jam"
    lua_setglobal(L, "jam");
    
    // Initialize the io table (this also overrides print)
    init_io(x);
    
    // Call jam:init(io)
    lua_getglobal(L, "jam");
    lua_getfield(L, -1, "init");
    lua_pushvalue(L, -2);  // push jam table as self
    lua_getglobal(L, "io");
    
    if (lua_pcall(L, 2, 0, 0) != LUA_OK) {
        pd_error(x, "jam: error in init(): %s", lua_tostring(L, -1));
        lua_pop(L, 1);
        return -1;
    }
    
    lua_pop(L, 1);  // pop jam table
    
    // Send load confirmation to info outlet
    outlet_symbol(x->info_out, gensym("loaded"));
    post("jam: loaded %s", s->s_name);
    return 0;
}

// Handle tick/bang messages
static void jam_bang(t_jam *x) {
    lua_State *L = x->L;
    
    // Update io values
    update_io(x);
    
    // Call jam:tick(io)
    lua_getglobal(L, "jam");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return;
    }
    
    lua_getfield(L, -1, "tick");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return;
    }
    
    lua_pushvalue(L, -2);  // push jam table as self
    lua_getglobal(L, "io");
    
    if (lua_pcall(L, 2, 0, 0) != LUA_OK) {
        pd_error(x, "jam: error in tick(): %s", lua_tostring(L, -1));
        // Also send error to info outlet
        t_atom argv[2];
        SETSYMBOL(&argv[0], gensym("error"));
        SETSYMBOL(&argv[1], gensym(lua_tostring(L, -1)));
        outlet_list(x->info_out, &s_list, 2, argv);
        lua_pop(L, 1);
    }
    
    lua_pop(L, 1);  // pop jam table
    
    // Increment counters
    x->tc++;
}

// Handle list messages - pass to jam:onMessage(io, ...)
static void jam_list(t_jam *x, t_symbol *s, int argc, t_atom *argv) {
    lua_State *L = x->L;

    if (argc < 1) return;

    // Update io values first (like we do in jam_bang)
    update_io(x);

    // Get jam table
    lua_getglobal(L, "jam");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return;
    }

    // Get onMessage method
    lua_getfield(L, -1, "onMessage");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);  // pop function and jam table
        return;
    }

    // Push self (jam table)
    lua_pushvalue(L, -2);

    // Push io table (like tick does)
    lua_getglobal(L, "io");

    // Push all arguments
    for (int i = 0; i < argc; i++) {
        if (argv[i].a_type == A_FLOAT) {
            lua_pushnumber(L, atom_getfloat(&argv[i]));
        } else if (argv[i].a_type == A_SYMBOL) {
            lua_pushstring(L, atom_getsymbol(&argv[i])->s_name);
        }
    }

    // Call jam:onMessage(io, ...)
    if (lua_pcall(L, argc + 2, 0, 0) != LUA_OK) {
        pd_error(x, "jam: error in onMessage(): %s", lua_tostring(L, -1));
        lua_pop(L, 1);
    }

    lua_pop(L, 1);  // pop jam table
}

// Reset tick counter
static void jam_reset(t_jam *x) {
    x->tc = 0;
    outlet_symbol(x->info_out, gensym("reset"));
    post("jam: reset counters");
}

// Set BPM
static void jam_bpm(t_jam *x, t_floatarg f) {
    if (f > 0) {
        x->bpm = f;
        
        // Update io.bpm in Lua
        lua_State *L = x->L;
        lua_getglobal(L, "io");
        if (lua_istable(L, -1)) {
            lua_pushnumber(L, x->bpm);
            lua_setfield(L, -2, "bpm");
        }
        lua_pop(L, 1);
        
        post("jam: bpm set to %.1f", x->bpm);
    }
}

// Set TPB
static void jam_tpb(t_jam *x, t_floatarg f) {
    if (f > 0) {
        x->tpb = f;
        
        // Update io.tpb in Lua
        lua_State *L = x->L;
        lua_getglobal(L, "io");
        if (lua_istable(L, -1)) {
            lua_pushnumber(L, x->tpb);
            lua_setfield(L, -2, "tpb");
        }
        lua_pop(L, 1);
        
        post("jam: tpb set to %.0f", x->tpb);
    }
}

// Constructor
static void *jam_new(t_symbol *s, int argc, t_atom *argv) {
    t_jam *x = (t_jam *)pd_new(jam_class);
    
    // Set defaults
    x->tpb = 180.0;
    x->bpm = 100.0;
    x->tc = 0;
    
    // Parse arguments (optional: tpb, bpm)
    if (argc > 0 && argv[0].a_type == A_FLOAT)
        x->tpb = atom_getfloat(&argv[0]);
    if (argc > 1 && argv[1].a_type == A_FLOAT)
        x->bpm = atom_getfloat(&argv[1]);
    
    // Create outlets (left to right)
    x->msg_out = outlet_new(&x->x_obj, &s_list);   // musical messages
    x->info_out = outlet_new(&x->x_obj, &s_symbol); // info/debug
    
    // Initialize Lua
    x->L = luaL_newstate();
    luaL_openlibs(x->L);
    
    // Store pointer to this object in Lua registry
    lua_pushlightuserdata(x->L, x);
    lua_setfield(x->L, LUA_REGISTRYINDEX, "pd_jam_obj");
    
    // Set Lua package path to include current directory and lib/
    lua_getglobal(x->L, "package");
    lua_pushstring(x->L, "./?.lua;./lib/?.lua");
    lua_setfield(x->L, -2, "path");
    lua_pop(x->L, 1);
    
    post("jam: created with tpb=%.0f bpm=%.0f", x->tpb, x->bpm);
    
    return (void *)x;
}

// Destructor
static void jam_free(t_jam *x) {
    if (x->L) {
        lua_close(x->L);
    }
}

// Setup function
void jam_setup(void) {
    jam_class = class_new(gensym("jam"),
        (t_newmethod)jam_new,
        (t_method)jam_free,
        sizeof(t_jam),
        CLASS_DEFAULT,
        A_GIMME, 0);
    
    class_addbang(jam_class, jam_bang);
    class_addlist(jam_class, jam_list);  // Handle list messages
    class_addmethod(jam_class, (t_method)load_jam, 
                    gensym("load"), A_SYMBOL, 0);
    class_addmethod(jam_class, (t_method)jam_reset, 
                    gensym("reset"), 0);
    class_addmethod(jam_class, (t_method)jam_bpm, 
                    gensym("bpm"), A_FLOAT, 0);
    class_addmethod(jam_class, (t_method)jam_tpb, 
                    gensym("tpb"), A_FLOAT, 0);
}
