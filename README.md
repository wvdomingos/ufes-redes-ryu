# RYU SDN Framework
> **Disciplina**: Redes de Computadores
> **Prof. Dr. Magnus Martinello**
> **Desafio:** Emular uma topologia de rede utilizando Mininet e o Ryu SDN framework controlando a largura de banda com aplicações QoS.

### 📝 Tópicos
<!--ts-->
👉🏽 [Tecnologias](#tecnologias)
👉🏽 [Pré-requisitos](#pre-requisitos)
👉🏽 [Definições](#definicoes)
👉🏽 [Exemplo 1](#exemplo-1)
👉🏽 [Exemplo 2](#exemplo-2)
👉🏽 [Exemplo 3](#exemplo-3)
<!--te-->

<div id='tecnologias'/>

### 🛠️ Tecnologias
As tecnologias utilizadas foram:
* [Ryu](https://osrg.github.io/ryu-book/en/html/index.html)
* [OpenvSwitch](https://docs.openvswitch.org/en/latest/)
* [Mininet-WiFi](https://mininet-wifi.github.io/)

<div id='pre-requisitos'/> 

### 💻 Pré-requisitos
* [Ryu](https://osrg.github.io/ryu-book/en/html/index.html)

Instalação do Ryu
```bash
$ sudo apt-get install git python-dev python-setuptools python-pip
$ git clone https://github.com/osrg/ryu.git
$ cd ryu
$ sudo pip install .
```

* [OpenvSwitch](https://docs.openvswitch.org/en/latest/)

Instalação do Open vSwitch
```bash
$ sudo apt-get install openvswitch-switch dnsmasq
```

* [Mininet-WiFi](https://mininet-wifi.github.io/)

Instalação do Mininet-WiFi
```bash
$ git clone git://github.com/intrig-unicamp/mininet-wifi
$ cd mininet-wifi
$ sudo util/install.sh -Wlnfv
```
<div id='definicoes'/> 

### Definições

* **Ryu**
É um framework SDN baseado em componentes Python que fornece um grande conjunto de serviços de rede através de uma API bem definida, facilitando a criação de novos aplicativos de gerenciamento e controle de rede para vários dispositivos de rede. (MEDEIROS et al., 2015)

<br />

* **QoS**
QoS (Quality of Service) é uma tecnologia que pode transferir os dados de acordo com a prioridade com base no tipo de dados e reservar largura de banda de rede para uma determinada comunicação, a fim de se comunicar com uma largura de banda de comunicação constante na rede.

<div id='exemplo-1'/> 

### Exemplo 1
**Exemplo da operação do QoS por fluxo**
Nesse exemplo temos a criação de topologia, adicionando configurações de fila e regras para reservar largura de banda da rede. 

**Construindo o ambiente**
![](img\ryu-ex01.png)

```bash
$ sudo mn --mac --switch ovsk --controller remote -x
```

Inicie outro xterm para o controlador.
```bash
$ mininet> xterm c0
```

Em seguida, defina a versão do OpenFlow a ser usado em cada roteador para a versão 1.3 e defina para escutar na porta 6632 para acessar o OVSDB.

switch: s1 (root):
```bash
$ ovs-vsctl set Bridge s1 protocols=OpenFlow13
$ ovs-vsctl set-manager ptcp:6632
```

Em seguida, modifique simple_switch_13.py para registrar a entrada do fluxo no id da tabela: 1.

controller: c0 (root)
```bash
$ sed '/OFPFlowMod(/,/)/s/)/, table_id=1)/' ryu/ryu/app/simple_switch_13.py > ryu/ryu/app/qos_simple_switch_13.py
$ cd ryu/; python ./setup.py install
```

Finalmente, inicie rest_qos, qos_simple_switch_13 e rest_conf_switch no xterm do controlador.
controller: c0 (root)
```bash
$ ryu-manager ryu.app.rest_qos ryu.app.qos_simple_switch_13 ryu.app.rest_conf_switch
```

**Configuração da fila**

Definir ovsdb_addr para acessar OVSDB
Node: c0 (root):
```bash
$ curl -X PUT -d '"tcp:127.0.0.1:6632"' http://localhost:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr
```

Executar a configuração da Fila.
```bash
$ curl -X POST -d '{"port_name": "s1-eth1", "type": "linux-htb", "max_rate": "1000000", "queues": [{"max_rate": "500000"}, {"min_rate": "800000"}]}' http://localhost:8080/qos/queue/0000000000000001
```

**Configuração de QoS**
Instalar a seguinte entrada de fluxo no switch.

Node: c0 (root):
```bash
$ curl -X POST -d '{"match": {"nw_dst": "10.0.0.1", "nw_proto": "UDP", "tp_dst": "5002"}, "actions":{"queue": "1"}}' http://localhost:8080/qos/rules/0000000000000001
```

**Verificando a configuração**
Node: c0 (root):
```bash
$ curl -X GET http://localhost:8080/qos/rules/0000000000000001
```

**Medindo a largura de banda**
Inicie outro xterm em cada h1 e h2.

```bash
$ mininet> xterm h1 h2
```

Node: h1(1) (root):
```bash
$ iperf -s -u -i 1 -p 5001
```

Node: h1(2) (root):
```bash
$ iperf -s -u -i 1 -p 5002
```

Node: h2(1) (root):
```bash
$ iperf -c 10.0.0.1 -p 5001 -u -b 1M
```

Node: h2(2) (root):
```bash
$ iperf -c 10.0.0.1 -p 5002 -u -b 1M
```

**Vídeo do Exemplo 1**
[Exemplo 2](https://www.youtube.com/watch?v=TZFMCm6ZvdM) 

<div id='exemplo-2'/> 

### Exemplo 2
**Exemplo da operação de QoS usando DiffServ**
O exemplo a seguir divide os fluxos para as várias classes QoS no roteador de entrada do domínio DiffServ e controlar fluxos para cada classe. DiffServ encaminhe os pacotes de acordo com o PHB definido pelo valor DSCP, que é o primeiro campo de 6 bits em cabeçalho IP. 

**Construindo o ambiente**
![](img\ryu-ex02.png)

```bash
$ sudo mn --topo linear,2 --mac --switch ovsk --controller remote -x
```

Iniciar outro xterm para o controlador.
```bash
$ mininet> xterm c0
```

Definir a versão do OpenFlow a ser usado em cada roteador para a versão 1.3 e definir a porta 6632 para acessar o OVSDB.
switch: s1 (root):
```bash
$ ovs-vsctl set Bridge s1 protocols=OpenFlow13
$ ovs-vsctl set-manager ptcp:6632
```

switch: s2 (root):
```bash
$ ovs-vsctl set Bridge s2 protocols=OpenFlow13
```

Excluir o endereço IP que é atribuído automaticamente em cada host e defina um novo endereço IP.
host: h1:
```bash
$ ip addr del 10.0.0.1/8 dev h1-eth0
$ ip addr add 172.16.20.10/24 dev h1-eth0
```

host:h2:
```bash
$ ip addr del 10.0.0.2/8 dev h2-eth0
$ ip addr add 172.16.10.10/24 dev h2-eth0
```

Modifique rest_router.py para registrar a entrada do fluxo no id da tabela: 1.
controller: c0 (root):
```bash
$ sed '/OFPFlowMod(/,/)/s/0, cmd/1, cmd/' ryu/ryu/app/rest_router.py > ryu/ryu/app/qos_rest_router.py
$ cd ryu/; python ./setup.py install
```

Iniciar rest_qos, qos_rest_router e rest_conf_switch no xterm do controlador.
controller: c0 (root):
```bash
$ ryu-manager ryu.app.rest_qos ryu.app.qos_rest_router ryu.app.rest_conf_switch
```

**Configuração da fila**
Definir ovsdb_addr para acessar OVSDB.
Node: c0 (root):
```bash
$ curl -X PUT -d '"tcp:127.0.0.1:6632"' http://localhost:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr
```

Executar a configuração da Fila.
```bash
$ curl -X POST -d '{"port_name": "s1-eth1", "type": "linux-htb", "max_rate": "1000000", "queues":[{"max_rate": "1000000"}, {"min_rate": "200000"}, {"min_rate": "500000"}]}' http://localhost:8080/qos/queue/0000000000000001
```

**Configuração do roteador**
Definir o endereço IP e a rota padrão para cada roteador.
```bash
$ curl -X POST -d '{"address": "172.16.20.1/24"}' http://localhost:8080/router/0000000000000001

$ curl -X POST -d '{"address": "172.16.30.10/24"}' http://localhost:8080/router/0000000000000001

$ curl -X POST -d '{"gateway": "172.16.30.1"}' http://localhost:8080/router/0000000000000001

$ curl -X POST -d '{"address": "172.16.10.1/24"}' http://localhost:8080/router/0000000000000002

$ curl -X POST -d '{"address": "172.16.30.1/24"}' http://localhost:8080/router/0000000000000002

$ curl -X POST -d '{"gateway": "172.16.30.10"}' http://localhost:8080/router/0000000000000002
```

Registrar os roteadores como o gateway padrão para cada host.
host: h1:
```bash
$ ip route add default via 172.16.20.1
```

host: h2:
```bash
$ ip route add default via 172.16.10.1
```

**Configuração de QoS**
Instale a seguinte entrada de fluxo de acordo com o valor DSCP no roteador (s1).
Node: c0 (root):
```bash
$ curl -X POST -d '{"match": {"ip_dscp": "26"}, "actions":{"queue": "1"}}' http://localhost:8080/qos/rules/0000000000000001

$ curl -X POST -d '{"match": {"ip_dscp": "34"}, "actions":{"queue": "2"}}' http://localhost:8080/qos/rules/0000000000000001
```

Instale as seguintes regras de marcação do valor DSCP no roteador (s2).
Node: c0 (root):
```bash
$ curl -X POST -d '{"match": {"nw_dst": "172.16.20.10", "nw_proto": "UDP", "tp_dst": "5002"}, "actions":{"mark": "26"}}' http://localhost:8080/qos/rules/0000000000000002

$ curl -X POST -d '{"match": {"nw_dst": "172.16.20.10", "nw_proto": "UDP", "tp_dst": "5003"}, "actions":{"mark": "34"}}' http://localhost:8080/qos/rules/0000000000000002
```

**Verificando a configuração**
Verifique o conteúdo da configuração de cada switch.

Node: c0 (root):
```bash
$ curl -X GET http://localhost:8080/qos/rules/0000000000000001

$ curl -X GET http://localhost:8080/qos/rules/0000000000000002
```

**Medindo a largura de banda**
A seguir, h1 (servidor) escuta na porta 5001, 5002 e 5003 com protocolo UDP. h2 (cliente) envia tráfego UDP de 1Mbps para a porta 5001 em h1, tráfego UDP de 300Kbps para a porta 5002 em h1 e tráfego UDP de 600Kbps para a porta 5003.

Iniciar 2 xterm em h2.
```bash
mininet> xterm h2
mininet> xterm h2
```

Node: h1(1) (root):
```bash
$ iperf -s -u -p 5002 &

$ iperf -s -u -p 5003 &

$ iperf -s -u -i 1 5001
```

Node: h2(1) (root):
```bash
iperf -c 172.16.20.10 -p 5001 -u -b 1M
```

Node: h2(2) (root):
```bash
iperf -c 172.16.20.10 -p 5002 -u -b 300K
```

Node: h2(3) (root):
```bash
$ iperf -c 172.16.20.10 -p 5003 -u -b 600K
```

**Vídeo do Exemplo 2**
[Exemplo 2](https://www.youtube.com/watch?v=9KuoKrGXZUY) 

<div id='exemplo-3'/> 

### Exemplo 3
**Exemplo de operação de QoS usando Meter Table**
Nesse exemplo a rede é composta por vários domínios DiffServ (domínio DS). A medição de tráfego é executada pelo roteador (roteador de borda) localizado no limite do domínio DS, e o tráfego que excede a largura de banda especificada será remarcado. Normalmente, os pacotes remarcados são descartados preferencialmente ou tratados como classe de baixa prioridade. 

**Construindo o ambiente**
![](img\ryu-ex03.png)

Construir uma topologia usando um script python.
```bash
$ curl -O https://raw.githubusercontent.com/osrg/ryu-book/master/sources/qos_sample_topology.py
$ sudo python ./qos_sample_topology.py
```

Iniciar dois xterm para o controlador.
```bash
mininet> xterm c0
```

Modificar o simple_switch_13.py para registrar a entrada do fluxo no id da tabela: 1.
controller: c0 (root)
```bash
$ sed '/OFPFlowMod(/,/)/s/)/, table_id=1)/' ryu/ryu/app/simple_switch_13.py > ryu/ryu/app/qos_simple_switch_13.py
$ cd ryu/; python ./setup.py install
```

Iniciar rest_qos e qos_simple_switch_13 no xterm do controlador.
controller: c0 (root):
```bash
$ ryu-manager ryu.app.rest_qos ryu.app.qos_simple_switch_13
```

**Configurando QoS**
Instalar a entrada de fluxo de acordo com o valor DSCP no roteador (s1).
Node: c0 (root):
```bash
$ curl -X POST -d '{"match": {"ip_dscp": "0", "in_port": "2"}, "actions":{"queue": "1"}}' http://localhost:8080/qos/rules/0000000000000001

$ curl -X POST -d '{"match": {"ip_dscp": "10", "in_port": "2"}, "actions":{"queue": "3"}}' http://localhost:8080/qos/rules/0000000000000001

$ curl -X POST -d '{"match": {"ip_dscp": "12", "in_port": "2"}, "actions":{"queue": "2"}}' http://localhost:8080/qos/rules/0000000000000001

$ curl -X POST -d '{"match": {"ip_dscp": "0", "in_port": "3"}, "actions":{"queue": "1"}}' http://localhost:8080/qos/rules/0000000000000001

$ curl -X POST -d '{"match": {"ip_dscp": "10", "in_port": "3"}, "actions":{"queue": "3"}}' http://localhost:8080/qos/rules/0000000000000001

$ curl -X POST -d '{"match": {"ip_dscp": "12", "in_port": "3"}, "actions":{"queue": "2"}}' http://localhost:8080/qos/rules/0000000000000001
```

Instalar as seguintes entradas do medidor nos switches (s2, s3).
Node: c0 (root):
```bash
$ curl -X POST -d '{"match": {"ip_dscp": "10"}, "actions":{"meter": "1"}}' http://localhost:8080/qos/rules/0000000000000002

$ curl -X POST -d '{"meter_id": "1", "flags": "KBPS", "bands":[{"type":"DSCP_REMARK", "rate": "400", "prec_level": "1"}]}' http://localhost:8080/qos/meter/0000000000000002

$ curl -X POST -d '{"match": {"ip_dscp": "10"}, "actions":{"meter": "1"}}' http://localhost:8080/qos/rules/0000000000000003

$ curl -X POST -d '{"meter_id": "1", "flags": "KBPS", "bands":[{"type":"DSCP_REMARK", "rate": "400", "prec_level": "1"}]}' http://localhost:8080/qos/meter/0000000000000003
```

**Verificando a configuração**
Verificar o conteúdo da configuração de cada switch.
Node: c0 (root):
```bash
$ curl -X GET http://localhost:8080/qos/rules/0000000000000001
$ curl -X GET http://localhost:8080/qos/rules/0000000000000002
$ curl -X GET http://localhost:8080/qos/rules/0000000000000003
```

**Medindo a largura de banda**
Iniciar 4 xterm da seguinte maneira.
```bash
mininet> xterm h1 h2 h3 h3
```

Node: h1(1) (root):
```bash
iperf -s -u -p 5001 & iperf -s -u -p 5002 & iperf -s -u -p 5003 &
```

**Best-effort traffic & AF11 excess traffic**
Node: h2 (root):
```bash
$ iperf -c 10.0.0.1 -p 5001 -u -b 800K
```

Node: h3(1) (root):
```bash
$ iperf -c 10.0.0.1 -p 5002 -u -b 600K --tos 0x28
```

**AF11 excess traffic & Best-effort traffic & AF11 non-excess traffic**
Node: h2 (root):
```bash
$ iperf -c 10.0.0.1 -p 5001 -u -b 600K --tos 0x28
```

Node: h3(1) (root):
```bash
$ iperf -c 10.0.0.1 -p 5002 -u -b 500K
```

Node: h3(2) (root):
```bash
$ iperf -c 10.0.0.1 -p 5003 -u -b 400K --tos 0x28
```

**AF11 excess traffic & AF11 excess traffic**
Node: h2 (root):
```bash
$ iperf -c 10.0.0.1 -p 5001 -u -b 600K --tos 0x28
```

Node: h3(1) (root):
```bash
$ iperf -c 10.0.0.1 -p 5002 -u -b 600K --tos 0x28
```

**Vídeo do Exemplo 3**
Exemplo 3