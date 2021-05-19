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

def promptForInput(args):
  inputPath = input(messages['prompts']['pathInput'])
  while not (os.path.isfile(inputPath) or os.path.isdir(inputPath)):
    print(messages['errors']['pathInvalid'])
    inputPath = input(messages['prompts']['pathInput'])
  args.append(inputPath)
  return args

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

def getInputData(args):
  inputPath = args[1]

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
  data = getInputData(args)

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
  print(args)
  if len(args) == 1:
    args = promptForInput(args)
  elif len(args) == 2:
    args.append('processed.scss')
  elif len(args) > 3:
    args=[args[0],args[1],args[2]]

  if fileOrDir(args[1]) == False:
    checkedArgs = promptForInput([args[0]])
    checkedArgs.append(args[2])
    args = checkedArgs

  print(args)
  return args

def main(args):
  args = validateArgs(args)
  result = concatFiles(args)
  if result == False:
    return False
  print(result)

args = sys.argv
main(args)