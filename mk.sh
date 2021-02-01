#/bin/bash

# Little script for creating the structure of the repository. Feel free to copy

mk(){
  mkdir $1 && cd $1
  printf "# Задание $1\n\n<++>" > README.md
  cd ..
}

for i in {1..11}; do
  mk "1.$i"
done

for i in {1..4}; do
  mk "2.$i"
done
