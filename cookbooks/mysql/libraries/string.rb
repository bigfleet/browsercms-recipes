def random_string(length = 10, alpha_only = false)
  schars = "#{'0124356789' unless alpha_only}abcdefghijklmnopqrstuvwxyz"
  random = ""
  1.upto(length) { random += schars[rand(schars.length),1] }
  random.upcase
end