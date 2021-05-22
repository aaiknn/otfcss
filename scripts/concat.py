import os
import sys

messages = {
  'errors': {
    'argOverflow': 'Error: Argument overflow.',
    'datalessIn': 'Error: No data found in input file(s).',
    'missReadPerm': 'Error: Missing read permissions on file ',
    'pathInvalid': 'Error: The path that you\'ve provided isn\'t valid.'
  },
  'prompts': {
    'pathInput': 'Please provide a valid path to your Sass file(s):\n'
  }
}

def fileOrDir(path):
  if os.path.isfile(path):
    return 1
  elif os.path.isdir(path):
    return 2
  return False

def promptForInput(arg):
  if arg:
    print(arg + ' is not a valid path.')

  inputPath = input(messages['prompts']['pathInput'])
  while not (os.path.isfile(inputPath) or os.path.isdir(inputPath)):
    print(messages['errors']['pathInvalid'])
    inputPath = input(messages['prompts']['pathInput'])
  arg = inputPath

  return arg

def readFile(path):
  try:
    file = open(path, 'r')
  except PermissionError:
    print(messages['errors']['missReadPerm'] + path + '.')
    return PermissionError
  with file:
    data = gatherFileData(file, path)
    file.close()
    return data

def gatherFileData(file, fileHeader):
  header = '\n//------ ' + fileHeader + ' ------'
  data = [header]
  codeLines = file.readlines()
  codeLines = ''.join(codeLines)
  data.append(codeLines)
  data = '\n'.join(data)
  return data

def getInputData(arg):
  inputPath = arg

  if fileOrDir(inputPath) == 1:
    data = readFile(inputPath)

  elif fileOrDir(inputPath) == 2:
    data = []
    for root, dirs, files in os.walk(inputPath):

      for fileName in files:
        path = os.path.join(root, fileName)
        data.append(readFile(path))

    data = '\n'.join(data)

  return data

def writeFile(fileName, data):
  newFile = open(fileName, 'w')
  newFile.write(data)
  newFile.close

def concatFiles(args):
  data = ''

  if isinstance(args[1], str):
    data = getInputData(args[1])
  elif isinstance(args[1], list):
    # reversing assumes that --addInput attempts to set missing variables...
    for arg in reversed(args[1]):
      fileData = getInputData(arg)
      data+=fileData

  if data == False:
    return False
  if data == None:
    print(messages['errors']['datalessIn'])
    return False
  if isinstance(data, type(BaseException)):
    raise data

  outputPath = args[2]
  writeFile(outputPath, data)
  return outputPath

def validateArgs(args):
  if len(args) == 1:
    inputArg = promptForInput()
    args.append(inputArg)
  elif len(args) == 2:
    args.append('processed.scss')

  elif len(args) > 3:
    if '--amendInput' in args:
      i = args.index('--amendInput')
      arr = [args[1], args[i + 1]]
      args[1] = arr

    args=[args[0],args[1],args[2]]

  if isinstance(args[1], str):
    if fileOrDir(args[1]) == False:
      args[1] = promptForInput(args[1])

  elif isinstance(args[1], list):
    for arg in args[1]:
      if fileOrDir(arg) == False:
        j = args[1].index(arg)
        args[1][j] = promptForInput(arg)

  return args

def main(args):
  args = validateArgs(args)
  result = concatFiles(args)
  if result == False:
    return False
  print(result)

args = sys.argv
main(args)