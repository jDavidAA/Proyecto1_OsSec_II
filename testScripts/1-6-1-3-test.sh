#!/bin/bash

# Función para obtener el primer número de la salida de un comando
get_first_number() {
    echo "$1" | grep -oE '[0-9]+' | head -n1
}

# Ejecutar el primer comando y almacenar la salida en una variable
profiles_output=$(apparmor_status | grep profiles)

# Obtener el número de perfiles cargados y en modo de ejecución estricto
loaded_profiles=$(get_first_number "$profiles_output")
enforce_profiles=$(get_first_number "$(echo "$profiles_output" | grep "enforce mode")")

# Verificar si los números coinciden
if [ "$loaded_profiles" -eq "$enforce_profiles" ]; then
    # Ejecutar el segundo comando y almacenar la salida en una variable
    processes_output=$(apparmor_status | grep processes)

    # Obtener el número de procesos con perfiles definidos y en modo de ejecución estricto
    defined_processes=$(get_first_number "$processes_output")
    enforce_processes=$(get_first_number "$(echo "$processes_output" | grep "enforce mode")")

    # Verificar si los números coinciden
    if [ "$defined_processes" -eq "$enforce_processes" ]; then
        echo -e "\nPASS:\n All AppArmor Profiles are enforcing"
    else
        echo -e "\nFAIL:\n Not all AppArmor Profiles are enforcing"
    fi
else
    echo -e "\nFAIL:\n Not all AppArmor Profiles are enforcing"
fi