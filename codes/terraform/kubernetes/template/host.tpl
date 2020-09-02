[bastion]
${bastion}

[kubernetes_controller]
${kubernetes-controller}

[kubernetes_worker]
${kubernetes-worker}

[kubernetes:children]
kubernetes_controller
kubernetes_worker
