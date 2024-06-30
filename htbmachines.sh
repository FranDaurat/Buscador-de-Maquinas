#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

function ctrl_c(){
  echo -e "\n\n${redColour}[!] Saliendo...${endColour}\n"
  tput cnomr && exit 1
}

# Ctrl+C
trap ctrl_c INT

# Variables globales
main_url="https://htbmachines.github.io/bundle.js"

function helpPanel(){
  echo -e "\n${yellowColour}[+]${endColour} Uso:"
  echo -e "\t${purpleColour}-u${endColour} Descargar o actualizar archivos necesarios"
  echo -e "\t${purpleColour}-m${endColour} Buscar por nombre de máquina"
  echo -e "\t${purpleColour}-i${endColour} Buscar por direccion IP"
  echo -e "\t${purpleColour}-y${endColour} Obtener link de la resolucion de la maquina"
  echo -e "\t${purpleColour}-d${endColour} Buscar por dificultad de una maquina"
  echo -e "\t${purpleColour}-o${endColour} Buscar por sistema operativo"
  echo -e "\t${purpleColour}-s${endColour} Buscar por skills"
  echo -e "\t${purpleColour}-h${endColour} Mostrar este panel de ayuda"


}


function updateFiles(){
 
  if [ ! -f bundle.js ]; then  
    
    tput civis
    echo -e "\n${yellowColour}[+]${endColour} Descargando archivos necesarios..."
    curl -s $main_url > bundle.js 
    js-beautify bundle.js | sponge bundle.js
    echo -e "\n${yellowColour}[+]${endColour} Todos los archivos han sido descargados"
    tput cnorm
  
  else
    
    tput civis
    echo -e "\n${yellowColour}[+]${endColour} Comprobando si hay actualizaciones pendientes"
    curl -s $main_url > bundle_temp.js 
    js-beautify bundle_temp.js | sponge bundle_temp.js
    md5_temp_value=$(md5sum bundle_temp.js | awk '{print $1}')
    md5_original_value=$(md5sum bundle.js | awk '{print $1}')
    tput cnorm

    if [ "$md5_temp_value" == "$md5_original_value" ]; then
      
      echo -e "\n${yellowColour}[+]${endColour} No hay actualizaciones pendientes"
      rm bundle_temp.js
    
    else 
      
      echo -e "\n${yellowColour}[+]${endColour} Hay actualizaciones pendientes"
      sleep 1
      rm bundle.js && mv bundle_temp.js bundle.js
      echo -e "\n${yellowColour}[+]${endColour} Se han aplicado las actualizaciones necesarias"
    fi

  fi
}

function searchMachine(){
  machineName="$1" 
  machineName_checker="$(cat bundle.js | awk "/name: \"${machineName}\"/,/resuelta:/" | grep -vE "id:|sku:|resuelta" | tr -d '"' | tr -d ',' | sed 's/^ *//')"
  if [ "$machineName_checker" ]; then
    echo -e "\n${yellowColour}[+]${endColour} Listando propiedades de la maquina ${purpleColour}${machineName}${endColour}:\n"
    cat bundle.js | awk "/name: \"${machineName}\"/,/resuelta:/" | grep -vE "id:|sku:|resuelta" | tr -d '"' | tr -d ',' | sed 's/^ *//'
  else
    echo -e "\n${redColour}[!] La máquina solicitada no existe${endColour}\n"
  fi
}

function searchIP(){
  ipAddress="$1"

  machineName="$(cat bundle.js | grep "ip: \"${ipAddress}\"," -B 3 | grep "name: " | awk 'NF{print $NF}' | tr -d '"' | tr -d ',')"
  
  if [ "$machineName" ]; then
    echo -e "\n${yellowColour}[+]${endColour} La maquina correspondiente para la IP $ipAddress es ${purpleColour}$machineName${endColour}"
    searchMachine $machineName
  else
    echo -e "\n${redColour}[!] No hay ninguna máquina asociada a esa IP${endColour}\n"
  fi 
}

function getYoutubeLink(){
  machineName="$1"
  youtubeLink="$(cat bundle.js | awk "/name: \"Tentacle\"/,/resuelta:/" | grep -vE "id:|sku:|resuelta" | tr -d '"' | tr -d ',' | sed 's/^ *//' | grep youtube | awk 'NF{print $NF}')"

  if [ "$youtubeLink" ]; then
    echo -e "\n${yellowColour}[+]${endColour} Resolucion de la maquina: $youtubeLink"
  else
    echo -e "\n${redColour}[!] No hay ningun enlace asociado a esa máquina${endColour}\n"
  fi

}

function getDifficulty(){
  difficulty="$1"
  results="$(cat bundle.js | grep "dificultad: \"$difficulty\"" -B 5 | grep "name:" | awk 'NF{print $NF}' | tr -d '"' | tr -d ',' | column)"

  if [ "$results" ]; then
    echo -e "\n${yellowColour}[+]${endColour} Máquinas con dificultad ${purpleColour}$difficulty${endColour}: \n"
    cat bundle.js | grep "dificultad: \"$difficulty\"" -B 5 | grep "name:" | awk 'NF{print $NF}' | tr -d '"' | tr -d ',' | column
  else
    echo -e "\n${redColour}[!] La dificultad indicada no existe${endColour}\n"
  fi
}

function searchOS(){
  os="$1"
  os_results="$(cat bundle.js | grep "so: \"$os\"" -B 5 | grep "name: " | awk 'NF{print $NF}' | tr -d '"' | tr -d ',' | column)"

  if [ "$os_results" ]; then
    echo -e "\n${yellowColour}[+]${endColour} Mostrando máquinas $os:\n\n$os_results ${purpleColour}$difficulty${endColour} \n"
  else
     echo -e "\n${redColour}[!] El sistema operativo  no existe${endColour}\n"
  fi

}

function getOSDifficulty(){
  difficulty="$1"
  os="$2"
  results="$(cat bundle.js | grep "so: \"$os\"" -C 4 | grep "dificultad: \"$difficulty\"" -B 5 | grep "name:" | awk 'NF{print $NF}' | tr -d '"' | tr -d "," | column)"
  if [ "$results" ];then 
        echo -e "\n${yellowColour}[+]${endColour} Mostrando máquinas $os con dificultad $difficulty:\n$results"
  else
    echo -e "\n${redColour}[!] Error... no es posible esa combinacion${endColour}\n"
  fi
}

function searchSkills(){
  skills="$1" 
  results="$(cat bundle.js | grep "skills:" -B 6 | grep -i "$skills" -B 6 | grep "name: " | awk 'NF{print $NF}' | tr -d '"' | tr -d "," | column)"
   if [ "$results" ];then 
        echo -e "\n${yellowColour}[+]${endColour} Mostrando máquinas que involucren $skills:\n$results"
  else
    echo -e "\n${redColour}[!] No se ha encontrado esa skill${endColour}\n"
  fi
}

# Indicadores
declare -i parameter_counter=0

# Chivatos
declare -i chivato_difficulty=0
declare -i chivato_os=0

while getopts "m:ui:y:d:o:s:h" arg; do
  case $arg in
    m) machineName=$OPTARG; let parameter_counter+=1;;
    u) let parameter_counter+=2;;
    i) ipAddress=$OPTARG; let parameter_counter+=3;;
    y) machineName=$OPTARG; let parameter_counter+=4;;
    d) difficulty=$OPTARG; chivato_difficulty=1; let parameter_counter+=5;;
    o) os=$OPTARG; chivato_os=1; let parameter_counter+=6;;
    s) skills="$OPTARG"; let parameter_counter+=7;;
    h) ;;
  esac
done

if [ $parameter_counter -eq 1 ]; then 
  searchMachine $machineName
elif [ $parameter_counter -eq 2 ]; then
  updateFiles
elif [ $parameter_counter -eq 3 ]; then
  searchIP $ipAddress
elif [ $parameter_counter -eq 4 ]; then
  getYoutubeLink $machineName
elif [ $parameter_counter -eq 5 ]; then
  getDifficulty $difficulty
elif [ $parameter_counter -eq 6 ]; then
  searchOS $os
elif [ $chivato_difficulty -eq 1 ] && [ $chivato_os -eq 1 ]; then
  getOSDifficulty $difficulty $os
elif [ $parameter_counter -eq 7 ]; then
  searchSkills "$skills"
else
  helpPanel
fi
