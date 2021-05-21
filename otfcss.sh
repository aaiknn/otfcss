#! /bin/sh

sassOutput=0

function printHelp(){
  helpText="\nUsage:"
  helpText+="\n\toftcss [options]"
  helpText+="\n\totfcss -i (<input-file-path> | <input-dir-path>) [-o <out-file-name>]"
  helpText+="\n\totfcss -h | --help"
  helpText+="\n\totfcss --version"
  helpText+="\n\nOptions:"
  helpText+="\n\t-h | --help\t\t\tShow this help."
  helpText+="\n\t-i <path> | --input <path>\tSpecify Sass input file or directory."
  helpText+="\n\t-o <name> | --output <name>\tSpecify CSS output file name."
  helpText+="\n\t--version\t\t\tShow version."
  helpText+="\n"
  echo $helpText
}

function printVersion(){
  versionNo="v0.2.1"
  echo $versionNo
}

function parseArgs(){
  POSITIONALS=()
  while [[ $# -gt 0 ]]; do
    flag="$1"

    case $flag in
      -h|--help|--version)
      shift
      ;;
      -i|--input)
      sassInput="$2"
      shift
      shift
      ;;
      -o|--output)
      sassOutput="$2"
      shift
      shift
      ;;
      *)                #unknown
      POSITIONALS+=("$1")
      shift
      ;;
    esac
  done
  set -- "${POSITIONALS[@]}"

  if [[ $sassOutput != 0 ]]; then
    outputFile=$sassOutput
  else
    # Shortcut for input:
    # If there's only one arg, and it's not a flag, assume it's what's supposed to go in
    if [[ $# = 1 ]] && [[ $1 != "-".* ]]; then
      sassInput=$1
    fi

    outputFile='processed.scss'
  fi
}

function processSass() {
  cssExt='.css'
  cssOut=$outputFile$cssExt
  sass $outputFile $cssOut --no-source-map --stop-on-error

  if [[ $? = 0 ]]; then
    echo "Successfully wrote CSS file $cssOut."
    sassErrorCode="NONE"
  else
    echo "Task failed while processing CSS."
    sassErrorCode=`cat $cssOut | grep 'Error:' | awk '$1=="/*"{print$2" "$3" "$4" "$5}'`
    rm $cssOut
  fi

  if [[ $sassErrorCode =~ "variable" ]]; then
    echo "Error: Missing data.\n"

  elif [[ $sassErrorCode =~ "mixin" ]]; then
    echo "Error: Oh no, mixin not found, apparently!\n"

  elif [[ $sassErrorCode =~ "target selector" ]]; then
    echo "Error: Ohps, extend target missing, apparently!\n"

  elif [[ $sassErrorCode =~ "xpected" ]]; then
    echo "Error: No valid Sass input provided.\n"
  fi

  if [[ $sassErrorCode =~ ^"Error" ]]; then
    if [[ $1 == "--continuous-interactive" ]]; then
      interactiveInput
    else
      troubleshootSass
    fi
  fi

  if [[ $sassErrorCode = "NONE" ]]; then
    rm $outputFile
    unset sassErrorCode
  fi
}

function interactiveInput() {
  echo "Declare missing input for $sassErrorCode"
  read additionalInteractiveInput
  echo $additionalInteractiveInput > _missingInput.scss
  cat $outputFile >> _missingInput.scss
  cat _missingInput.scss > $outputFile
  rm _missingInput.scss
  processSass --continuous-interactive
}

function troubleshootSass() {
  echo "\nYou might be missing some extra input. Pick an option:
    1: Provide a path to an additional sass file or directory of sass files
    2: Declare missing input interactively from the cli
    3: Exit"
  read chosenOption

  if [[ $chosenOption = "1" ]]; then
    echo "Move on with moar input for $sassErrorCode"
    #read additionalInput
    #echo $additionalInteractiveInput > _missingInput.scss
    #cat $outputFile
  elif [[ $chosenOption = "2" ]]; then
    interactiveInput
  elif [[ $chosenOption = "3" ]]; then
    rm $outputFile
  fi
}

function processFiles() {
  python3 scripts/concat.py $sassInput $outputFile

  if [[ $? = 0 ]]; then
    processSass
  else
    echo "Task failed while concatenating input files."
  fi
}

function main(){
  parseArgs "$@"

  for i in "$@"; do
    case $i in
      -h|--help)
        printHelp
        exit
      ;;
      --version)
        printVersion
        exit
      ;;
    esac
  done

  processFiles
  exit
}

main "$@"