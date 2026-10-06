#!/bin/bash

# ==========================================
# FUNÇÃO DE TRATAMENTO DE ERROS
# ==========================================
checar_erro() {
    local codigo_retorno=$1
    local mensagem_falha=$2

    if [ "$codigo_retorno" -ne 0 ]; then
        echo
        echo "=========================================="
        echo " AVISO: FALHA DETECTADA!"
        echo "=========================================="
        echo "Detalhe: $mensagem_falha"
        echo "=========================================="
        echo
        read -p "Deseja ignorar essa falha e continuar o restante do processo? (s/n): " resposta
        
        case "$resposta" in
            [sS]|[sS][iI][sS][tT][eE][mM]|[sS][iI])
                echo "Continuando a execução por opção do operador..."
                echo
                return 0
                ;;
            *)
                echo "Processo abortado pelo operador devido a falha."
                exit 1
                ;;
        esac
    fi
}

# ==========================================
# CONFIGURAÇÕES GERAIS
# ==========================================
DIRETORIO_PDV="/Zanthus/Zeus/pdvJava"
ARQUIVO_XML="$DIRETORIO_PDV/INFOPDV.XML"
CAMINHO_ZEUS="/Zanthus/Zeus"

# Arquivo de Atualização Codfon (Versão 834)
ARQUIVO_ATUALIZACAO="ZMAN_1_X_X_834_CW.EXL"
URL_CODFON="https://raw.githubusercontent.com/equipepdvtec/privado/main/$ARQUIVO_ATUALIZACAO"

FTP_USER="pdvtec"

# ==========================================
# LINKS RAW DO GITHUB (EQUIPEPDVTEC)
# ==========================================
URL_99_LEITOR="https://raw.githubusercontent.com/equipepdvtec/privado/main/99-leitor.rules"
URL_99_BALANCA="https://raw.githubusercontent.com/equipepdvtec/privado/main/99-balanca.rules"
URL_98_SINALIZADOR="https://raw.githubusercontent.com/equipepdvtec/privado/main/98-sinalizador.rules"
URL_99_IMPRESSORA="https://github.com/equipepdvtec/privado/raw/refs/heads/main/99-Impressora.rules"

URL_LOG_SO="https://raw.githubusercontent.com/equipepdvtec/privado/main/Log.so"
URL_PERTO_INI="https://raw.githubusercontent.com/equipepdvtec/privado/main/PertoSensorBoard.ini"
URL_LIB_PERTO="https://raw.githubusercontent.com/equipepdvtec/privado/main/libPertoSensorBoard.so.1.0.3.2"

URL_PDVT_TOUCH="https://raw.githubusercontent.com/equipepdvtec/privado/main/PDVTouch.sh"
URL_INTERFACE="https://raw.githubusercontent.com/equipepdvtec/privado/main/Interface.tar.gz"

# Laurent
URL_LAURENT_ECFRECEB="https://raw.githubusercontent.com/equipepdvtec/privado/main/laurent/ECFRECEB.CFG"
URL_LAURENT_EMUL="https://raw.githubusercontent.com/equipepdvtec/privado/main/laurent/EMUL.INI.txt"

# Módulo PHP PDV (Fallback GitHub)
URL_MODULO_PHP_GITHUB="https://raw.githubusercontent.com/equipepdvtec/privado/main/moduloPHPPDV_2_14_184_159c_26086_php_8_1.zip"

# Bibliotecas Zanthus (Fallback GitHub)
URL_SO_U64_GITHUB="https://github.com/equipepdvtec/privado/releases/download/libs-v1/so_u64.zip"
URL_SO_U22_GITHUB="https://github.com/equipepdvtec/privado/releases/download/libs-v1/so_u22.zip"

# Bibliotecas CliSiTef 64 bits
URL_LIB_CLISITEF="https://github.com/equipepdvtec/clisitef/raw/refs/heads/main/112p64bits/libclisitef.so"
URL_LIB_CURL64="https://github.com/equipepdvtec/clisitef/raw/refs/heads/main/112p64bits/libcurl64.so"
URL_LIB_EMV64="https://github.com/equipepdvtec/clisitef/raw/refs/heads/main/112p64bits/libemv64.so"
URL_LIB_QRENCODE64="https://github.com/equipepdvtec/clisitef/raw/refs/heads/main/112p64bits/libqrencode64.so"

# CliSiTef.ini
URL_CLISITEF_INI="https://github.com/equipepdvtec/privado/raw/refs/heads/main/CliSiTef.ini"

# ==========================================
# VALIDAR ROOT
# ==========================================
if [ "$EUID" -ne 0 ]; then
    echo "Execute como root."
    echo "Exemplo: sudo bash configura_self.sh"
    exit 1
fi

echo "=========================================="
echo " SELECIONE O MODELO DO SELF"
echo "=========================================="
echo "1) PERTO"
echo "2) Laurent"
read -p "Digite o número correspondente ao modelo [1 ou 2]: " OPCAO_MODELO

case $OPCAO_MODELO in
    1)
        MODELO_SELF="PERTO"
        ;;
    2)
        MODELO_SELF="LAURENT"
        ;;
    *)
        echo "Opção inválida. Abortando instalação."
        exit 1
        ;;
esac

echo "Modelo selecionado: $MODELO_SELF"
echo

read -s -p "Digite a senha do FTP Zanthus: " FTP_PASS
echo
echo

# ==========================================
# ETAPA 1: ATUALIZAR CODFON
# ==========================================
echo "=== Iniciando atualização do Codfon ==="

if [ -d "$DIRETORIO_PDV" ]; then
    cd "$DIRETORIO_PDV" || exit 1
else
    checar_erro 1 "O diretório $DIRETORIO_PDV não existe."
fi

if [ -f "$ARQUIVO_XML" ]; then
    OPERADOR=$(grep -oP '(?<=<OPERADOR>).*?(?=</OPERADOR>)' "$ARQUIVO_XML" | head -n 1)
    if [ -z "$OPERADOR" ]; then
        OPERADOR=0
    fi

    if [ "$OPERADOR" -gt 0 ]; then
        checar_erro 1 "Existe operador logado no PDV (ID: $OPERADOR)."
    else
        echo "Validação de operador: OK."
    fi

    VERSAO_ATUAL=$(grep -oP '(?<=<VERSAO>).*?(?=</VERSAO>)' "$ARQUIVO_XML" | head -n 1)
    echo "Versão atual detectada: $VERSAO_ATUAL"

    NUM_VERSAO_ATUAL=$(echo "$VERSAO_ATUAL" | grep -oP '\d+$')
    NUM_VERSAO_NOVA="834"

    if [ -z "$NUM_VERSAO_ATUAL" ]; then
        echo "Aviso: não foi possível detectar a versão atual com precisão."
    else
        if [ "$NUM_VERSAO_ATUAL" -ge "$NUM_VERSAO_NOVA" ]; then
            echo "Codfon já está na versão $VERSAO_ATUAL ou superior."
        else
            echo "Baixando Codfon 834..."
            wget -O "$ARQUIVO_ATUALIZACAO" "$URL_CODFON"
            checar_erro $? "Erro ao baixar o Codfon do GitHub."

            echo "Encerrando aplicação..."
            pkill -9 pdvJava2
            pkill -9 lnx
            pkill -9 jav
            pkill -9 chro

            sleep 2

            echo "Extraindo Codfon..."
            tar -zxvf "$ARQUIVO_ATUALIZACAO"
            checar_erro $? "Erro ao extrair $ARQUIVO_ATUALIZACAO."

            echo "Codfon atualizado com sucesso."
        fi
    fi
else
    checar_erro 1 "Arquivo INFOPDV.XML não encontrado."
fi

# ==========================================
# ETAPA 2: BIBLIOTECAS (FTP ZANTHUS E CLISITEF 64)
# ==========================================
echo
echo "=== Iniciando atualização das bibliotecas ==="

ARQUITETURA=$(uname -m)
echo "Arquitetura detectada: $ARQUITETURA"

if [ "$ARQUITETURA" = "x86_64" ]; then
    echo "Sistema 64 bits."

    baixar_lib_ftp_ou_github() {
        local PASTA_DESTINO="$1"
        local PASTA_FTP="$2"
        local URL_GITHUB="$3"
        local ZIP_GITHUB="$4"

        while true; do
            cd "$PASTA_DESTINO" || exit 1
            echo "Baixando bibliotecas $PASTA_FTP via FTP Zanthus..."
            wget --user "$FTP_USER" --password="$FTP_PASS" -c -r -nd -np "ftp://ftp.zanthus.com.br:2142/pub/Zeus_Frente_de_Loja/_Complementares/$PASTA_FTP/"

            if [ $? -eq 0 ]; then
                echo "Bibliotecas $PASTA_FTP baixadas via FTP com sucesso."
                return 0
            fi

            echo
            echo "Falha no download via FTP. A senha pode estar incorreta ou o FTP pode estar indisponível."
            echo "1) Digitar a senha novamente e tentar o FTP"
            echo "2) Baixar as bibliotecas pelo GitHub"
            read -p "Escolha [1/2]: " OPCAO_LIB

            case "$OPCAO_LIB" in
                1)
                    read -s -p "Digite novamente a senha do FTP Zanthus: " FTP_PASS
                    echo
                    ;;
                2)
                    echo "Baixando $ZIP_GITHUB pelo GitHub..."
                    rm -f "$ZIP_GITHUB"
                    wget -O "$ZIP_GITHUB" "$URL_GITHUB"
                    checar_erro $? "Erro ao baixar $ZIP_GITHUB pelo GitHub."

                    echo "Validando $ZIP_GITHUB..."
                    unzip -t "$ZIP_GITHUB" >/dev/null 2>&1
                    checar_erro $? "O arquivo $ZIP_GITHUB baixado do GitHub não é um ZIP válido."

                    TEMP_LIB=$(mktemp -d)
                    checar_erro $? "Erro ao criar diretório temporário para $ZIP_GITHUB."

                    unzip -o "$ZIP_GITHUB" -d "$TEMP_LIB"
                    checar_erro $? "Erro ao descompactar $ZIP_GITHUB."

                    if [ -d "$TEMP_LIB/$PASTA_FTP" ]; then
                        cp -a "$TEMP_LIB/$PASTA_FTP/." "$PASTA_DESTINO/"
                        checar_erro $? "Erro ao copiar as bibliotecas de $PASTA_FTP para $PASTA_DESTINO."
                    else
                        echo "ERRO: A pasta $PASTA_FTP não foi encontrada dentro de $ZIP_GITHUB."
                        rm -rf "$TEMP_LIB"
                        rm -f "$ZIP_GITHUB"
                        checar_erro 1 "Estrutura inesperada no arquivo $ZIP_GITHUB."
                    fi

                    echo "Aplicando permissão 777 em todos os arquivos de $PASTA_DESTINO..."
                    find "$PASTA_DESTINO" -type f -exec chmod 777 {} +
                    checar_erro $? "Erro ao aplicar permissão 777 nos arquivos de $PASTA_DESTINO."

                    rm -rf "$TEMP_LIB"
                    rm -f "$ZIP_GITHUB"
                    echo "Bibliotecas $PASTA_FTP instaladas pelo GitHub com sucesso em $PASTA_DESTINO."
                    return 0
                    ;;
                *)
                    echo "Opção inválida. Escolha 1 ou 2."
                    ;;
            esac
        done
    }

    if [ -d "$CAMINHO_ZEUS/lib_u64" ]; then
        baixar_lib_ftp_ou_github "$CAMINHO_ZEUS/lib_u64" "so_u64" "$URL_SO_U64_GITHUB" "so_u64.zip"
    fi

    if [ -d "$CAMINHO_ZEUS/lib_u22" ]; then
        baixar_lib_ftp_ou_github "$CAMINHO_ZEUS/lib_u22" "so_u22" "$URL_SO_U22_GITHUB" "so_u22.zip"

        # Baixar bibliotecas CliSiTef de 64 bits para lib_u22
        echo "Baixando bibliotecas CliSiTef 64 bits para /Zanthus/Zeus/lib_u22..."
        wget -L -O libclisitef.so "$URL_LIB_CLISITEF"
        checar_erro $? "Erro ao baixar libclisitef.so."

        wget -L -O libcurl64.so "$URL_LIB_CURL64"
        checar_erro $? "Erro ao baixar libcurl64.so."

        wget -L -O libemv64.so "$URL_LIB_EMV64"
        checar_erro $? "Erro ao baixar libemv64.so."

        wget -L -O libqrencode64.so "$URL_LIB_QRENCODE64"
        checar_erro $? "Erro ao baixar libqrencode64.so."

        chmod 777 libclisitef.so libcurl64.so libemv64.so libqrencode64.so
        echo "Permissão 777 aplicada às bibliotecas CliSiTef 64 bits em lib_u22."
    fi
else
    echo "Sistema 32 bits."

    if [ -d "$CAMINHO_ZEUS/lib" ]; then
        cd "$CAMINHO_ZEUS/lib" || exit 1
        wget --user "$FTP_USER" --password="$FTP_PASS" -c -r -nd -np ftp://ftp.zanthus.com.br:2142/pub/Zeus_Frente_de_Loja/_Complementares/so/
        checar_erro $? "Erro ao baixar bibliotecas so via FTP."
    fi

    if [ -d "$CAMINHO_ZEUS/lib_ubu" ]; then
        cd "$CAMINHO_ZEUS/lib_ubu" || exit 1
        wget --user "$FTP_USER" --password="$FTP_PASS" -c -r -nd -np ftp://ftp.zanthus.com.br:2142/pub/Zeus_Frente_de_Loja/_Complementares/so_ubu/
        checar_erro $? "Erro ao baixar bibliotecas so_ubu via FTP."
    fi

    if [ -d "$CAMINHO_ZEUS/lib_co5" ]; then
        cd "$CAMINHO_ZEUS/lib_co5" || exit 1
        wget --user "$FTP_USER" --password="$FTP_PASS" -c -r -nd -np ftp://ftp.zanthus.com.br:2142/pub/Zeus_Frente_de_Loja/_Complementares/so_co5/
        checar_erro $? "Erro ao baixar bibliotecas so_co5 via FTP."
    fi
fi

echo "Executando ldconfig..."
ldconfig
checar_erro $? "Erro ao executar ldconfig."

echo "Bibliotecas atualizadas."

# ==========================================
# ETAPA 3: MÓDULO PHP PDV (FTP + FALLBACK GITHUB)
# ==========================================
echo
echo "=== Iniciando atualização do MóduloPHPPDV ==="

PASTA_MODULO="/Zanthus/Zeus/pdvJava/GERAL/SINCRO/WEB/moduloPHPPDV"
XML_VERSAO_MODULO="/Zanthus/Zeus/pdvJava/MODULOPHP_VERSAO.XML"
ZIP_PHP81="moduloPHPPDV_2_14_184_159c_26086_php_8_1.zip"
VERSAO_ALVO_EXATA="2_14_184_159c"
FORCAR_ATUALIZACAO=false

if [ -d "$PASTA_MODULO" ]; then
    cd "$PASTA_MODULO" || exit 1
else
    checar_erro 1 "A pasta $PASTA_MODULO não existe."
fi

if [ -f "$XML_VERSAO_MODULO" ]; then
    VERSAO_MODULO_TEXTO=$(grep -oP '(?<=<versao>).*?(?=</versao>)' "$XML_VERSAO_MODULO" | head -n 1)
    VERSAO_MODULO_LEMBRADA=$(echo "$VERSAO_MODULO_TEXTO" | tr '.' '_')

    echo "Versão do módulo detectada: $VERSAO_MODULO_TEXTO"

    if [ "$VERSAO_MODULO_LEMBRADA" != "$VERSAO_ALVO_EXATA" ]; then
        FORCAR_ATUALIZACAO=true
    fi
else
    echo "MODULOPHP_VERSAO.XML não encontrado. Atualização será forçada."
    FORCAR_ATUALIZACAO=true
fi

if [ "$FORCAR_ATUALIZACAO" = true ]; then
    echo "Tentando baixar Módulo PHP via FTP Zanthus..."
    wget --user "$FTP_USER" --password="$FTP_PASS" -c "ftp://ftp.zanthus.com.br:2142/pub/Zeus_Retail/ModuloPDV_8_1/$ZIP_PHP81"
    
    # Se o FTP falhar, tenta via GitHub
    if [ $? -ne 0 ] || [ ! -f "$ZIP_PHP81" ]; then
        echo "Aviso: Falha no download do Módulo PHP via FTP. Tentando via GitHub..."
        wget -O "$ZIP_PHP81" "$URL_MODULO_PHP_GITHUB"
        checar_erro $? "Erro ao baixar Módulo PHP via GitHub."
    fi

    unzip -o "$ZIP_PHP81"
    checar_erro $? "Erro ao descompactar o Módulo PHP."

    echo "Módulo PHP atualizado."
else
    echo "Módulo PHP já está na versão correta."
fi

# ==========================================
# ETAPA 4: ATUALIZAR INTERFACE SELF
# ==========================================
echo
echo "=== Atualizando Interface do SELF ==="

cd /Zanthus/Zeus || exit 1

wget -O Interface.tar.gz "$URL_INTERFACE"
checar_erro $? "Erro ao baixar Interface.tar.gz."

tar -zxvf Interface.tar.gz
checar_erro $? "Erro ao extrair Interface.tar.gz."

echo "Interface do SELF atualizada."

# ==========================================
# ETAPA 5: BAIXAR REGRAS UDEV
# ==========================================
echo
echo "=== Baixando regras UDEV do SELF ==="

cd /etc/udev/rules.d || exit 1

wget -O 99-leitor.rules "$URL_99_LEITOR"
checar_erro $? "Erro ao baixar 99-leitor.rules."

wget -O 99-balanca.rules "$URL_99_BALANCA"
checar_erro $? "Erro ao baixar 99-balanca.rules."

wget -O 98-sinalizador.rules "$URL_98_SINALIZADOR"
checar_erro $? "Erro ao baixar 98-sinalizador.rules."

wget -O 99-Impressora.rules "$URL_99_IMPRESSORA"
checar_erro $? "Erro ao baixar 99-Impressora.rules."

chmod 644 /etc/udev/rules.d/99-leitor.rules
chmod 644 /etc/udev/rules.d/99-balanca.rules
chmod 644 /etc/udev/rules.d/98-sinalizador.rules
chmod 644 /etc/udev/rules.d/99-Impressora.rules

udevadm control --reload-rules
udevadm trigger

echo "Regras UDEV aplicadas."

# ==========================================
# ETAPA 6: ARQUIVOS PERTO OU CONFIG LAURENT
# ==========================================
if [ "$MODELO_SELF" = "PERTO" ]; then
    echo
    echo "=== Baixando arquivos PERTO para pdvJava ==="

    cd "$DIRETORIO_PDV" || exit 1

    wget -O Log.so "$URL_LOG_SO"
    checar_erro $? "Erro ao baixar Log.so."

    wget -O PertoSensorBoard.ini "$URL_PERTO_INI"
    checar_erro $? "Erro ao baixar PertoSensorBoard.ini."

    wget -O libPertoSensorBoard.so.1.0.3.2 "$URL_LIB_PERTO"
    checar_erro $? "Erro ao baixar libPertoSensorBoard."

    chmod 755 Log.so
    chmod 644 PertoSensorBoard.ini
    chmod 755 libPertoSensorBoard.so.1.0.3.2

    echo "Arquivos PERTO baixados."
else
    echo
    echo "=== Configurando Laurent em pdvJava ==="

    cd "$DIRETORIO_PDV" || exit 1

    # Configuração do Sinalizador Arduino do Laurent
    cat << 'EOF' > ZSINALIZ_LAURENTI_ARDUINO.CFG
modelo=1
linux_device=/dev/ttyUSB1
EOF
    checar_erro $? "Erro ao criar o arquivo ZSINALIZ_LAURENTI_ARDUINO.CFG."
    chmod 777 ZSINALIZ_LAURENTI_ARDUINO.CFG

    echo "Configuração do Laurent aplicada com sucesso."
fi

echo
echo "=========================================="
echo " CONFIGURAÇÃO DA IMPRESSORA"
echo "=========================================="
read -p "A impressora instalada é ELGIN I9 FULL? (s/n): " IMPRESSORA_ELGIN

case "$IMPRESSORA_ELGIN" in
    [sS]|[sS][iI][mM])
        echo "Configurando impressora ELGIN I9 FULL..."
        cd "$DIRETORIO_PDV" || exit 1

        wget -O ECFRECEB.CFG "$URL_LAURENT_ECFRECEB"
        checar_erro $? "Erro ao baixar ECFRECEB.CFG."

        wget -O EMUL.INI "$URL_LAURENT_EMUL"
        checar_erro $? "Erro ao baixar EMUL.INI."

        if [ -f "$DIRETORIO_PDV/ECF9F.CFG" ]; then
            echo "Ajustando $DIRETORIO_PDV/ECF9F.CFG..."
            sed -i '/^[[:space:]]*PORTA_IF=/d' "$DIRETORIO_PDV/ECF9F.CFG"
            echo "PORTA_IF=4" >> "$DIRETORIO_PDV/ECF9F.CFG"
            checar_erro $? "Erro ao configurar PORTA_IF=4 em ECF9F.CFG."
            echo "PORTA_IF=4 configurado com sucesso no ECF9F.CFG."
        else
            echo "Aviso: ECF9F.CFG não encontrado em $DIRETORIO_PDV para configurar PORTA_IF=4."
        fi

        echo "Configuração da ELGIN I9 FULL aplicada com sucesso."
        ;;
    *)
        echo "Impressora não é ELGIN I9 FULL. Configuração específica não será aplicada."
        ;;
esac

# ==========================================
# ETAPA 7: BACKUP E TROCA DO PDVTouch.sh E CLISITEF.INI
# ==========================================
echo
echo "=== Atualizando PDVTouch.sh e CliSiTef.ini ==="

cd "$DIRETORIO_PDV" || exit 1

if [ -f "$DIRETORIO_PDV/PDVTouch.sh" ]; then
    cp "$DIRETORIO_PDV/PDVTouch.sh" "$DIRETORIO_PDV/PDVTouch.sh.bkp.$(date +%Y%m%d_%H%M%S)"
    echo "Backup do PDVTouch.sh criado."
fi

wget -O PDVTouch.sh "$URL_PDVT_TOUCH"
checar_erro $? "Erro ao baixar o PDVTouch.sh."

chmod +x PDVTouch.sh

echo "Baixando CliSiTef.ini para pdvJava..."
wget -L -O CliSiTef.ini "$URL_CLISITEF_INI"
checar_erro $? "Erro ao baixar o CliSiTef.ini."

echo "PDVTouch.sh e CliSiTef.ini atualizados com sucesso."

# ==========================================
# ETAPA 8: CONFIGURAR ÁUDIO
# ==========================================
echo
echo "=== Configurando áudio do SELF ==="

STARTUP="/usr/local/bin/startup"

if [ -f "$STARTUP" ]; then
    cp "$STARTUP" "$STARTUP.bkp.$(date +%Y%m%d_%H%M%S)"
    sed -i 's/^amixer -c 0 set Master .*/amixer -c 0 set Master 70% unmute/' "$STARTUP"
    checar_erro $? "Erro ao configurar o volume no arquivo startup."

    echo "Áudio configurado: Master 70% unmute."
else
    echo "Aviso: arquivo $STARTUP não encontrado."
fi

# ==========================================
# ETAPA 9: COPIAR CONFIGURAÇÕES DE OUTRO PDV
# ==========================================
echo
echo "=== Copiando configurações de outro PDV ==="

if ! command -v sshpass >/dev/null 2>&1; then
    echo "Instalando sshpass..."
    apt update && apt install -y sshpass
    checar_erro $? "Erro ao instalar o pacote sshpass."
fi

# Opções para impedir que SSH/SCP fiquem aguardando indefinidamente
SSH_OPCOES="-o StrictHostKeyChecking=no -o ConnectTimeout=5 -o ServerAliveInterval=5 -o ServerAliveCountMax=1"
TIMEOUT_SSH=15
TIMEOUT_SCP=30
PULAR_COPIA=false

while true; do
    read -p "Digite o IP do PDV origem: " IP_ORIGEM

    if [ -z "$IP_ORIGEM" ]; then
        echo "Nenhum IP informado. Pulando etapa de cópia."
        PULAR_COPIA=true
        break
    fi

    echo "Verificando comunicação SSH com o PDV origem $IP_ORIGEM..."
    timeout "$TIMEOUT_SSH" sshpass -p "zanthus" ssh $SSH_OPCOES user@"$IP_ORIGEM" "exit" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "Comunicação com $IP_ORIGEM: OK."
        break
    fi

    echo
    echo "=========================================="
    echo " NÃO FOI POSSÍVEL ACESSAR O PDV ORIGEM"
    echo "=========================================="
    echo "IP informado: $IP_ORIGEM"
    echo "O IP pode estar incorreto, o PDV pode estar desligado ou o SSH pode estar indisponível."
    echo
    echo "1) Digitar outro IP e tentar novamente"
    echo "2) Pular a etapa de cópia"
    read -p "Escolha [1/2]: " OPCAO_IP

    case "$OPCAO_IP" in
        1)
            echo
            ;;
        2)
            echo "Etapa de cópia ignorada por opção do operador."
            PULAR_COPIA=true
            break
            ;;
        *)
            echo "Opção inválida. Digite o IP novamente."
            echo
            ;;
    esac
done

if [ "$PULAR_COPIA" = false ]; then
    cd "$DIRETORIO_PDV" || exit 1

    echo "Copiando arquivos CFG e INI..."
    timeout "$TIMEOUT_SCP" sshpass -p "zanthus" scp $SSH_OPCOES -r user@"$IP_ORIGEM":/Zanthus/Zeus/pdvJava/ZMWS*.CFG .
    timeout "$TIMEOUT_SCP" sshpass -p "zanthus" scp $SSH_OPCOES -r user@"$IP_ORIGEM":/Zanthus/Zeus/pdvJava/RESTG*.CFG .
    timeout "$TIMEOUT_SCP" sshpass -p "zanthus" scp $SSH_OPCOES -r user@"$IP_ORIGEM":/Zanthus/Zeus/pdvJava/CARG*.CFG .
    timeout "$TIMEOUT_SCP" sshpass -p "zanthus" scp $SSH_OPCOES -r user@"$IP_ORIGEM":/Zanthus/Zeus/pdvJava/RCB*.CFG .
    timeout "$TIMEOUT_SCP" sshpass -p "zanthus" scp $SSH_OPCOES -r user@"$IP_ORIGEM":/Zanthus/Zeus/pdvJava/CliSiTef.ini .
    timeout "$TIMEOUT_SCP" sshpass -p "zanthus" scp $SSH_OPCOES -r user@"$IP_ORIGEM":/Zanthus/Zeus/pdvJava/ECF9.CFG .

    rm -f simula.ecf param.ecf
    echo "Tentando copiar simula.ecf..."
    timeout "$TIMEOUT_SCP" sshpass -p "zanthus" scp $SSH_OPCOES -r user@"$IP_ORIGEM":/Zanthus/Zeus/pdvJava/simula.ecf .

    if [ -f "$DIRETORIO_PDV/simula.ecf" ]; then
        echo "simula.ecf copiado. Executando util_R90..."
        ./util_R90.xz64 PROG=simula.ecf
        checar_erro $? "Erro ao executar util_R90 para simula.ecf."
    else
        echo "simula.ecf não encontrado. Tentando copiar param.ecf..."
        timeout "$TIMEOUT_SCP" sshpass -p "zanthus" scp $SSH_OPCOES -r user@"$IP_ORIGEM":/Zanthus/Zeus/pdvJava/param.ecf .

        if [ -f "$DIRETORIO_PDV/param.ecf" ]; then
            echo "param.ecf copiado. Executando util_R90..."
            ./util_R90.xz64 PROG=param.ecf
            checar_erro $? "Erro ao executar util_R90 para param.ecf."
        else
            echo "Aviso: nem simula.ecf nem param.ecf foram copiados."
        fi
    fi
    echo "Configurações copiadas."
fi

# ==========================================
# ETAPA 10: ALTERAR GRUB / UARTS
# ==========================================
echo
echo "=== Configurando GRUB para liberar portas ttyS ==="

if [ -f /etc/default/grub ]; then
    cp /etc/default/grub /etc/default/grub.bkp.$(date +%Y%m%d_%H%M%S)

    # Remove qualquer 8250.nr_uarts existente
    sed -i 's/ *8250.nr_uarts=[0-9]*//g' /etc/default/grub

    # Adiciona 8250.nr_uarts=2 no GRUB_CMDLINE_LINUX_DEFAULT
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="8250.nr_uarts=2 /' /etc/default/grub

    update-grub
    checar_erro $? "Erro ao rodar update-grub."

    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck
    checar_erro $? "Erro ao rodar grub-install."

    update-grub
    update-initramfs -u -k all
    checar_erro $? "Erro ao atualizar initramfs."

    echo "GRUB alterado com sucesso."
else
    checar_erro 1 "Arquivo /etc/default/grub não encontrado."
fi

# ==========================================
# FINAL
# ==========================================
echo
echo "=========================================="
echo " CONFIGURAÇÃO DO SELF CONCLUÍDA ($MODELO_SELF)"
echo "=========================================="
echo
echo "Reinicie o SELF para aplicar."
