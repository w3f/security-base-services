# security-base-services

helmfile driven secure base services powered by **1PASSWORD connect server** ,**Bank-VAULT** , **ARGOCD-server** to manage predefined application.


## Functionality
Project based self driven, Fully Automated **Secure Platform** to host **Internal Applications**  managed by [Argo-CD](https://argo-cd.readthedocs.io/en/stable/#:~:text=Argo%20CD%20is%20implemented%20as,target%20state%20is%20considered%20OutOfSync%20.) application controllers.


Pre-define project scope to instruct **Argo-CD** to adopt deployed application. 

Example Project
----------------
Projects provide a **logical grouping** of applications, which is useful when **Argo CD** is used by **multiple teams**. 

Projects provide the following features:
* **restrict** what may be deployed (**trusted Git source repositories**)
* **restrict** where apps may be deployed to (**destination clusters and namespaces**)
* **restrict** what `kinds` of objects may or may not be deployed (e.g. `RBAC`, `CRDs`, `DaemonSets`, `NetworkPolicy` etc...)
* defining **project roles** to provide application **RBAC** (bound to OIDC groups and/or JWT tokens)

```yaml=
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: "$PROJECT_NAME"
  #Managed by controller in:
  namespace: argocd
  # Finalizer that ensures that project is not deleted until it is not referenced by any application
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  # Project description
  description: "$Describe_Application"

  # Allow manifests to deploy from any Git repos
  sourceRepos:
  - '*'

  # Only permit applications to deploy to thier manifest generated namespace in the same cluster
  destinations:
  - namespace: '*'
    server: '*'

  # Deny all cluster-scoped resources from being created, except for Namespace
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'

```

## Example root-application

Declaratively specify one Argo CD app that consists only of other apps.
this is so called [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/).
exteremly usefull for **Cluster Bootstrapping**, **Disaster Recovery** scenarios.

```yaml=
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-$APPLICATION_NAME
  #Managed by:
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    namespace: default
    name: in-cluster
  project: $PROJECT_NAME
  source:
    #Insert path to directory hosting your applications
    path: argocd/$NEW_PATH
    repoURL: https://github.com/w3f/security-base-services.git
    targetRevision: HEAD
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
    syncOptions:
      - CreateNamespace=true

```
   
## Example Application
Refer to path of desired applications to be managed by argo-cd:

```yaml=
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  labels:
  name: $APPLICATION_NAME  
#Managed by:
  namespace: argocd
spec:
  destination:
    server: 'https://kubernetes.default.svc'
  # Must match Or assign Value "Default"
  project: $PROJECT_NAME
  source:
    path: .
    plugin:
      name: helmfile
    repoURL: 'https://github.com/w3f/$REPO_NAME.git'
    # Can be assingned to branches for troubleshooting & Enviorment re-creation
    targetRevision: HEAD
  syncPolicy:
    automated: null
    syncOptions:
      - CreateNamespace=true
      - ApplyOutOfSyncOnly=true
```

