
lambda { |stdout,stderr,status|
  output = stdout + stderr
  return :green   if /^(\d+) test(s?), 0 failures/.match(output)
  return :red     if /^(\d+) test(s?), (\d+) failure(s?)/.match(output)
  return :amber
}
