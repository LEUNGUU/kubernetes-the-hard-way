[bastion]
${bastion}

[kubernetes-controller]
${kubernetes-controller}

[kubernetes-worker]
${kubernetes-worker}

[kubernetes:children]
kubernetes-controller
kubernetes-worker
