#! /bin/zsh

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
  versionNo="v0.1.0"
  echo $versionNo
}

function parseArgs(){
  POSITIONALS=()
  while [[ $# -gt 0 ]]
  do
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
}

function handleSass(){
  if [ -v sassOutput ]; then
    outputFile=$sassOutput
  else
    outputFile='processed.scss'
  fi

  python3 otfcss.py $sassInput $outputFile

  if [ $? = "0" ]; then
    cssExt='.css'
    cssOut=$outputFile$cssExt
    sass $outputFile $cssOut --no-source-map --stop-on-error

    if [ $? = "0" ]; then
      echo "Successfully wrote CSS file $cssOut."
    else
      echo "Task failed while processing CSS."
      sassErrorCode=`cat $cssOut | grep 'Error:' | awk '$1=="/*"{print$2" "$3" "$4" "$5}'`
      rm $cssOut
    fi

    rm $outputFile
  fi

  if [[ $sassErrorCode =~ "variable" ]]; then
    echo "Error: Missing data.\n"
    #echo "\nYou might be missing some variable declarations in your input files. Pick an option:\n1: Provide additional sass input or\n2: Declare missing variables interactively\n3: Exit"
    #read chosenOption

    #if [[ $chosenOption = "1" ]]; then
    #  echo "Move on with moar input"
    #elif [[ $chosenOption = "2" ]]; then
    #  echo "Move on with interactive variable declaration"
    #fi

  elif [[ $sassErrorCode =~ "mixin" ]]; then
    echo "Error: Oh no, mixin not found, apparently!\n"

  elif [[ $sassErrorCode =~ "target selector" ]]; then
    echo "Error: Ohps, extend target missing, apparently!\n"

  elif [[ $sassErrorCode =~ "xpected" ]]; then
    echo "Error: No valid Sass input provided.\n"
  fi

  exit
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

  handleSass
}

main "$@"