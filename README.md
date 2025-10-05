# Roteiro de Instalação do n8n no Rancher RKE2 com Kubernetes

Este roteiro detalha a instalação do n8n como um serviço no seu cluster Rancher RKE2, utilizando Kubernetes, e configurando um Ingress para acesso local através do endereço `n8n.local` em um namespace dedicado.

## 1. Pré-requisitos

Antes de iniciar, certifique-se de que você possui os seguintes pré-requisitos:

*   Um cluster Rancher RKE2 em funcionamento.
*   `kubectl` configurado e autenticado para interagir com o seu cluster Kubernetes.
*   Um Ingress Controller (como o NGINX Ingress Controller) instalado e em execução no seu cluster. Se você não tiver um, a instalação do NGINX Ingress Controller é um passo fundamental e deve ser realizada antes de prosseguir.
*   A StorageClass `local-path` deve estar configurada e disponível no seu cluster RKE2 para persistência de dados local. O RKE2 geralmente vem com o `local-path-provisioner` pré-instalado, o que facilita o uso desta StorageClass.

## 2. Criação do Namespace

É uma boa prática isolar aplicações em namespaces dedicados. Vamos criar um namespace chamado `n8n` para todos os recursos relacionados ao n8n.

```bash
kubectl create namespace n8n
```

## 3. Criação dos Manifests Kubernetes

Crie os seguintes arquivos YAML no seu ambiente local. Estes arquivos definirão o Deployment, Persistent Volume Claim (PVC), Service, Secret e Ingress para o n8n, todos dentro do namespace `n8n`.

### 3.1. `n8n-deployment.yaml`

Este arquivo define o Deployment do n8n, especificando a imagem, portas, variáveis de ambiente e montagem do volume persistente.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: n8n
  namespace: n8n
  labels:
    app: n8n
spec:
  replicas: 1
  selector:
    matchLabels:
      app: n8n
  template:
    metadata:
      labels:
        app: n8n
    spec:
      containers:
        - name: n8n
          image: n8nio/n8n
          ports:
            - containerPort: 5678
          env:
            - name: N8N_HOST
              value: "n8n.local"
            - name: WEBHOOK_URL
              value: "http://n8n.local/"
            - name: N8N_PROTOCOL
              value: "http"
            - name: N8N_PORT
              value: "5678"
            - name: N8N_BASIC_AUTH_ACTIVE
              value: "true"
            - name: N8N_BASIC_AUTH_USER
              valueFrom:
                secretKeyRef:
                  name: n8n-secret
                  key: N8N_BASIC_AUTH_USER
            - name: N8N_BASIC_AUTH_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: n8n-secret
                  key: N8N_BASIC_AUTH_PASSWORD
          volumeMounts:
            - name: n8n-data
              mountPath: /home/node/.n8n
      volumes:
        - name: n8n-data
          persistentVolumeClaim:
            claimName: n8n-pvc
```

### 3.2. `n8n-pvc.yaml`

Define um Persistent Volume Claim para o n8n, garantindo que os dados do n8n (workflows, credenciais, etc.) sejam persistidos mesmo se o pod for reiniciado ou realocado. Este PVC utiliza a `storageClassName: local-path` para provisionamento de volume local.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: n8n-pvc
  namespace: n8n
  labels:
    app: n8n
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 5Gi
```

### 3.3. `n8n-service.yaml`

Cria um Service Kubernetes para expor o Deployment do n8n internamente no cluster.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: n8n
  namespace: n8n
  labels:
    app: n8n
spec:
  selector:
    app: n8n
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5678
```

### 3.4. `n8n-secret.yaml`

Este Secret armazenará as credenciais de autenticação básica para o n8n. **Você precisará substituir os placeholders pelos seus próprios valores codificados em Base64.**

Para gerar os valores em Base64, use os seguintes comandos no seu terminal:

```bash
echo -n "seu_usuario" | base64
echo -n "sua_senha" | base64
```

Substitua `<base64_encoded_username>` e `<base64_encoded_password>` pelos valores gerados.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: n8n-secret
  namespace: n8n
type: Opaque
data:
  N8N_BASIC_AUTH_USER: <base64_encoded_username>
  N8N_BASIC_AUTH_PASSWORD: <base64_encoded_password>
```

### 3.5. `n8n-ingress.yaml`

Configura um Ingress para rotear o tráfego externo para o serviço n8n, usando o hostname `n8n.local`.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: n8n-ingress
  namespace: n8n
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: HTTP
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
    - host: n8n.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: n8n
                port:
                  number: 80
```

## 4. Aplicação dos Manifests no Cluster

Após criar e configurar os arquivos YAML, aplique-os no seu cluster Kubernetes na seguinte ordem, especificando o namespace `n8n`:

1.  **Secret**: Crie o Secret primeiro, pois o Deployment depende dele.
    ```bash
    kubectl apply -f n8n-secret.yaml -n n8n
    ```

2.  **Persistent Volume Claim (PVC)**:
    ```bash
    kubectl apply -f n8n-pvc.yaml -n n8n
    ```

3.  **Deployment**: Implante o n8n.
    ```bash
    kubectl apply -f n8n-deployment.yaml -n n8n
    ```

4.  **Service**: Crie o Service para expor o n8n.
    ```bash
    kubectl apply -f n8n-service.yaml -n n8n
    ```

5.  **Ingress**: Configure o Ingress para acesso externo.
    ```bash
    kubectl apply -f n8n-ingress.yaml -n n8n
    ```

Verifique o status dos recursos criados no namespace `n8n`:

```bash
kubectl get pods,svc,pvc,ingress -n n8n
```

Certifique-se de que o pod do n8n está em estado `Running` e que o Ingress foi provisionado corretamente.

## 5. Configuração de DNS Local

Para acessar o n8n através de `n8n.local` na sua rede local, você precisará mapear este hostname para o endereço IP externo do seu Ingress Controller.

1.  **Obtenha o IP do Ingress Controller**: O IP externo do seu Ingress Controller pode ser obtido com o seguinte comando. Lembre-se de que o Ingress Controller geralmente não roda no namespace `n8n`, mas sim em um namespace próprio (comumente `ingress-nginx`).
    ```bash
    kubectl get services -n ingress-nginx
    # Ou o namespace onde seu Ingress Controller está instalado
    ```
    Procure pelo serviço do tipo `LoadBalancer` (ou `NodePort` se você estiver usando uma configuração diferente) e anote o `EXTERNAL-IP`.

2.  **Edite o arquivo `hosts`**: No seu computador local (ou em qualquer máquina que precise acessar `n8n.local`), edite o arquivo `hosts`.

    *   **Linux/macOS**: `/etc/hosts`
    *   **Windows**: `C:\Windows\System32\drivers\etc\hosts`

    Adicione a seguinte linha, substituindo `<EXTERNAL-IP-DO-INGRESS>` pelo IP que você obteve:

    ```
    <EXTERNAL-IP-DO-INGRESS> n8n.local
    ```

    Salve o arquivo.

## 6. Acesso ao n8n

Após todas as configurações, você poderá acessar o n8n abrindo seu navegador e navegando para `http://n8n.local`.

Você será solicitado a inserir as credenciais de autenticação básica que você configurou no `n8n-secret.yaml`.

## Referências

*   [n8n-io/n8n-kubernetes-hosting](https://github.com/n8n-io/n8n-kubernetes-hosting)
*   [How to deploy n8n in Kubernetes - k3s](https://sysadmin.info.pl/en/blog/how-to-deploy-n8n-in-kubernetes-k3s/)
*   [N8n Kubernetes installation using PVC](https://community.n8n.io/t/n8n-kubernetes-installation-using-pvc/10191)
*   [Kubernetes Deployment for n8n: Best Practices and Easy Setup](https://medium.com/localtechid/easy-way-setup-n8n-on-kubernetes-environment-34ce17a2c051)
*   [NGINX ingress controller for n8n - how to create it and deploy in Kubernetes](https://sysadmin.info.pl/en/blog/nginx-ingress-controller-for-n8n-how-to-create-it-and-deploy-in-kubernetes/)

