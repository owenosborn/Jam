local jam = {}

function jam:init(io)
end

function jam:tick(io)
  
  if io.on(1) then 
      io.pn(60) 
  end     

end

return jam
