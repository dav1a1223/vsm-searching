#!/bin/bash
# Put your command below to execute your program.
# Replace "./my-program" with the command that can execute your program.
# Remember to preserve " $@" at the end, which will be the program options we give you.
while [ "$1" != "" ]; do
    case $1 in
        -i)           shift
                      query_file=$1
                      ;;
        -o)           shift
                      outfile_name=$1
                      ;;
        -m)           shift
                      model_dir=$1
                      ;;
        -d)           shift
                      ntcir_dir=$1
                      ;;
        -r)           feedback=1
                      ;;
        *)            exit 1
                      ;;
    esac
    shift
done

if [[ ${feedback} = 1 ]]; then
    ruby irhw1.rb 1 ${query_file} ${outfile_name} ${model_dir} ${ntcir_dir}
else
    ruby irhw1.rb 0 ${query_file} ${outfile_name} ${model_dir} ${ntcir_dir}
fi
