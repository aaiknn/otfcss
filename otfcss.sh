#! /bin/sh

sassOutput=0

function printHelp(){
  printf "
  Usage:
      oftcss [options]
      otfcss -i (<input-file-path> | <input-dir-path>) [-o <out-file-name>]
      otfcss -h | --help
      otfcss --version\n\n
  Options:
      -h | --help\t\t\tShow this help.
      -i <path> | --input <path>\tSpecify Sass input file or directory.
      -I | --interactive\t\tIf an error occurs during Sass processing, skip the prompt
            \t\t\t\tand jump directly into interactive troubleshooting.
      -o <name> | --output <name>\tSpecify CSS output file name.
      --version\t\t\t\tShow version.\n\n"
}

function printVersion(){
  versionNo="v0.2.2"
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
      -I|--interactive)
      interactive=1
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
    printf "\nError: Missing data."

  elif [[ $sassErrorCode =~ "mixin" ]]; then
    printf "\nError: Oh no, mixin not found, apparently!"

  elif [[ $sassErrorCode =~ "target selector" ]]; then
    printf "\nError: Ohps, extend target missing, apparently!"

  elif [[ $sassErrorCode =~ "xpected" ]]; then
    printf "\nError: No valid Sass input provided."
  fi

  if [[ $sassErrorCode =~ ^"Error" ]]; then
    if [[ $1 = "--continuous-interactive" || $interactive = "1" ]]; then 
      echo $interactive
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
  printf "Declare missing input for $sassErrorCode...\n"
  read additionalInteractiveInput
  echo $additionalInteractiveInput > _missingInput.scss
  cat $outputFile >> _missingInput.scss
  cat _missingInput.scss > $outputFile
  rm _missingInput.scss
  processSass --continuous-interactive
}

function troubleshootSass() {
  printf "\nYou might be missing some extra input. Pick an option:
    1: Provide a path to an additional sass file or directory of sass files
    2: Declare missing input interactively from the cli
    3: Exit\n"
  read chosenOption

  if [[ $chosenOption = "1" ]]; then
    printf "This feature isn't yet implemented."
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