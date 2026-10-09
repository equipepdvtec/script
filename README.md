# Download
- Link para download
https://tinyurl.com/selfroldao
- Comando para download
wget -O selfconfig.sh https://tinyurl.com/selfroldao

# SELF Config

Script desenvolvido para automatizar a configuração e atualização do ambiente **Zanthus SELF/PDV**, reduzindo procedimentos manuais durante instalação, formatação e manutenção dos equipamentos.

## Principais funções

O script realiza automaticamente diversas etapas de configuração do SELF, incluindo:

- Atualização do **ZMAN/CODFON**. **ATUAL 834CW**
- Download e instalação das **bibliotecas do sistema**, identificando o ambiente utilizado.
- Suporte às bibliotecas `so_u22` e `so_u64`.
- Extração das bibliotecas diretamente para `/Zanthus/Zeus/lib_u22` ou `/Zanthus/Zeus/lib_u64`.
- Aplicação de permissão `777` aos arquivos das bibliotecas instaladas.
- Download e atualização do **moduloPHPPDV**. **ATUAL _2_14_184_159c_26086_php_8_1**
- Atualização da pasta/interface utilizada pelo SELF.
- Instalação das regras **UDEV** necessárias para os periféricos, incluindo leitores, balanças, sinalizador e impressoras.
- Instalação das bibliotecas utilizadas pelos equipamentos **Perto**.
- Atualização/configuração do `PDVTouch.sh`.
- Ajustes relacionados ao **GRUB/UARTS** para funcionamento das portas utilizadas pelos periféricos.
- Download de arquivos pelo **FTP**, com tratamento para senha incorreta e possibilidade de nova tentativa.
- Alternativa de download das bibliotecas através do **GitHub** quando necessário.

O objetivo é deixar o SELF preparado com os arquivos, bibliotecas, regras e configurações necessárias para funcionamento do sistema Zanthus e seus periféricos, padronizando o procedimento realizado pelos técnicos.

> **Observação:** após a conclusão do processo, verificar as mensagens apresentadas pelo script e realizar a reinicialização do equipamento quando indicada.
