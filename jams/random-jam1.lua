local jam = {}

function jam:init(io)

    self.count = 0
    
end

function jam:tick(io)
  
  if io.on(1/2) then 
      self.count = self.count + 1
      io.pn((self.count % 20) + 50) 
  end    

  if io.on(1) then
      io.pn(math.random(40, 80))
  end

  if io.on(1/6) then
      io.pn(math.random(40, 80))
  end


end

return jam
