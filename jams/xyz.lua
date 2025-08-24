local jam = {}

function ra()
    return math.random(1,4)
end

function jam:init(io)

    self.count = 0
    
end

function jam:tick(io)
  
  if io.on(1/ra()) then 
      self.count = self.count + 1
      io.pn((self.count % 20) + 60, {dur=.8}) 
  end    

  if io.on(1/4.1) then
     io.pn(math.random(40, 50))
  end

  if io.on(1/4) then
      io.pn(math.random(70, 80))
  end


end

return jam
