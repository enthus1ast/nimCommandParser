## Parses a syntax like this:
## foo baa
## "foo baa" "some more"
## "foo\"s baa"
## "foo's baa"

import parseutils
import strutils

type ChatCommand* = ref object
  cmd*: string
  params*: seq[string]
proc `$`*(cmd: ChatCommand): string =
  return $cmd.cmd & " --> " & $cmd.params 

proc debugPrint(buffer: string, pos: int) = 
  var pointPos = if pos  < 0: 0 else: pos 
  echo buffer
  echo '-'.repeat(pointPos) & "^" , " := ", buffer[pos]

proc isChatCommand*(content: string ): bool =
  return content.strip().startsWith("/")


# iterator lexCommands*(line: string, seperators: set[char] = {}): string =
iterator lexCommands*(line: string, seperators: seq[char] = @[]): string =
  var param = ""
  var pos = 0
  var inSingle, inMulti, inEscape: bool = false
  var buf: string = ""
  var cur: char
  while pos < line.len:
    # echo buf
    # debugPrint(line,pos)
    cur = line[pos]
    case cur
    of '\\':
      if inEscape: buf.add cur; pos.inc; inEscape = false; continue
      inEscape = true
    of '"':
      if inEscape: buf.add cur; pos.inc; inEscape = false; continue
      if inSingle: buf.add cur; pos.inc; continue
      
      if inMulti: 
        pos.inc
        inMulti = false
        continue
      else: 
        inMulti = true
        pos.inc
        continue
      buf.add cur
    of '\'':
      if inEscape: buf.add cur; pos.inc; inEscape = false; continue
      if inMulti: buf.add cur; pos.inc; continue
      
      if inSingle: 
        # buf.add line[pos]
        pos.inc
        inSingle = false
        continue
      else: 
        inSingle = true
        pos.inc
        continue
      buf.add cur
    of ' ':
      if inEscape:
        buf.add cur
        pos.inc
        inEscape = false
        continue

      if inSingle or inMulti:
        buf.add cur 
        pos.inc
        continue
      else:
        yield buf
        buf.setLen(0)
    else: # case

      if cur in seperators and not inEscape and not (inSingle or inMulti) :
        # discard
        yield buf
        buf.setLen(0)
        yield $cur
      else:
        buf.add cur

        # if inEscape:
        #   buf.add cur
        #   pos.inc
        #   inEscape = false
        #   continue

        # if inSingle or inMulti:
        #   yield buf 
        #   buf.setLen(0)
        #   buf.add cur 
        #   pos.inc
        #   continue
        # else:
        #   yield buf
        #   buf.setLen(0)
      # else:
      #   buf.add cur
      # buf.add cur
    pos.inc

  if buf != "":
    yield buf
    buf.setLen(0)

    
proc newChatCommand*(line: string, stripSlash = true, seperators: seq[char] = @[]): ChatCommand = 
  result = ChatCommand()
  result.params = @[]
  result.cmd = ""
  var pos = 0
  if line[0] == '/' and stripSlash:
    pos = 1
  for each in lexCommands(line[pos..^1], seperators):
    if result.cmd.len == 0:
      result.cmd = each
    else:
      result.params.add each

when isMainModule:
  # echo newChatCommand("ab cc klaus peter \"hallo was geht\" \"das geht ja toll\" ")
  # echo newChatCommand("ab cc klaus peter 'hallo was\"geht' 'das geht ja toll''")
  assert newChatCommand("").cmd == ""
  assert newChatCommand("/").cmd == ""
  assert newChatCommand("foo").cmd == "foo"
  assert newChatCommand("/foo").cmd == "foo"

  assert newChatCommand("/foo baa").cmd == "foo"
  assert newChatCommand("/foo baa").params == @["baa"]
  assert newChatCommand("/foo baa baz").params == @["baa", "baz"]
  # echo newChatCommand("""/foo "baa baz"""").params
  assert newChatCommand("""/foo "baa baz"""").params == @["baa baz"]
  assert newChatCommand("""/foo "baa 'baz"""").params == @["baa 'baz"]
  assert newChatCommand("""/foo "baa 'baz" "klaus peter'udo"""").params == @["baa 'baz", "klaus peter'udo"]

  assert newChatCommand("""/foo "baa\"baz"""").params == @["baa\"baz"]
  assert newChatCommand("""/foo "baa\" baz"""").params == @["baa\" baz"]
  assert newChatCommand("""/foo "baa\' baz"""").params == @["baa\' baz"]
  assert newChatCommand("""/foo "baa' baz"""").params == @["baa\' baz"]
  assert newChatCommand("""/foo "baa\\baz"""").params == @["baa\\baz"]
  assert newChatCommand("""/foo "baa\\ baz"""").params == @["baa\\ baz"]


  block:
    let userinput = """self.foo() "asdasd|asdjhaksjdh" """
    let c = newChatCommand(userinput, false ,@['|', '.']) 
    assert c.cmd == "self"
    assert c.params == @[".", "foo()", "asdasd|asdjhaksjdh"]

  block:
    let userinput = """self.foo() asdasd|asdjhaksjdh """
    let c = newChatCommand(userinput, false ,@['|', '.']) 
    assert c.cmd == "self"
    assert c.params == @[".", "foo()", "asdasd", "|", "asdjhaksjdh"]    
    # for each in lexCommands(userinput, seperators = @['|']):
      # echo each 

  # let userinput = """/cmd param1 param2 "param in quotes" param4 "anoter param in quote" """
  # echo $newChatCommand(userinput)
