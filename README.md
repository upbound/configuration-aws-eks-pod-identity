# AWS EKS Pod Identity Configuration

This repository contains an Upbound project, tailored for users establishing their initial control plane with [Upbound](https://cloud.upbound.io). This configuration deploys fully managed AWS EKS Pod Identity resources.

## Overview

The core components of a custom API in [Upbound Project](https://docs.upbound.io/learn/control-plane-project/) include:

- **CompositeResourceDefinition (XRD):** Defines the API's structure.
- **Composition(s):** Configures the Functions Pipeline
- **Embedded Function(s):** Encapsulates the Composition logic and implementation within a self-contained, reusable unit

In this specific configuration, the API contains:

- **an [AWS EKS Pod Identity](/apis/definition.yaml) custom resource type.**
- **Composition:** Configured in [/apis/composition.yaml](/apis/composition.yaml)
- **Embedded Function:** The Composition logic is encapsulated within [embedded function](/functions/eks-pod-identity/main.k)

## How It Works

At a high level, EKS Pod Identity allows you to use the AWS API to define permissions that specific Kubernetes service accounts should have in AWS:

Setting up Pod Identity starts by installing an add-on:
https://github.com/aws/eks-pod-identity-agent

```bash
aws eks create-addon \
  --cluster-name cluster-name \
  --addon-name eks-pod-identity-agent
```

This sets up a new DaemonSet in the kube-system namespace:

```bash
$ kubectl get daemonset -n kube-system
NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
eks-pod-identity-agent   2         2         2       2            2           <none>
```

![pod-identity](images/s3-access-podidentity.png)

### EKS Pod Identity at a glance

```bash
aws eks create-pod-identity-association \
  --cluster-name your-cluster \
  --namespace default \
  --service-account pod-service-account \
  --role-arn arn:aws:iam::012345678901:role/YourPodRole
```

Here, YourPodRole has the following trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "pods.eks.amazonaws.com"
    },
    "Action": ["sts:AssumeRole","sts:TagSession"]
  }]
}
```

Once you've run the commands to configure Pod Identity, any pod that runs under the pod-service-account service account magically has access to AWS resources, through temporary Security Token Service (STS) credentials:

```bash
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-aws-access
spec:
  serviceAccountName: pod-service-account
  containers:
  - name: main
    image: public.ecr.aws/aws-cli/aws-cli
    command: ["sleep", "infinity"]
EOF

$ kubectl exec pod/pod-with-aws-access -- aws sts get-caller-identity
{
    "UserId": "XXXX",
    "Account": "012345678901",
    "Arn": "arn:aws:sts::012345678901:assumed-role/YourPodRole/eks-cluster-pod-xxx"
}
```

For a given EKS cluster, you can easily see which pods have access to AWS resources using eks:ListPodIdentityAssociations:

```bash
aws eks list-pod-identity-associations --cluster-name your-cluster

{
  "associations": [{
    {
            "clusterName": "your-cluster",
            "namespace": "default",
            "serviceAccount": "pod-service-account",
            "associationArn": "arn:aws:eks:us-east-1:012345678901:podidentityassociation/your-cluster/a-0123",
            "associationId": "a-0123"
        },

  }]
}
```

Then, you can use eks:DescribePodIdentityAssociation to retrieve the ARN of the role it maps to:

```bash
aws eks describe-pod-identity-association \
  --cluster-name your-cluster \
  --association-id a-0123

{
    "association": {
        "clusterName": "your-cluster",
        "namespace": "default",
        "serviceAccount": "pod-service-account",
        "roleArn": "arn:aws:iam::012345678901:role/YourRole"
    }
}
```

## Testing

The configuration can be tested using:

- `up composition render --xrd=apis/definition.yaml apis/composition.yaml examples/pod-identity-xr.yaml` to render the composition
- `up test run tests/*` to run composition tests in `tests/test-eks-pod-identity/`
- `up test run tests/* --e2e` to run end-to-end tests in `tests/e2etest-eks-pod-identity/`

## Deployment

- Execute `up project run`
- Alternatively, install the Configuration from the [Upbound Marketplace](https://marketplace.upbound.io/configurations/upbound/configuration-aws-eks-pod-identity)
- Check [examples](/examples/) for example XR(Composite Resource)

## Next steps

This repository serves as a foundational step. To enhance the configuration, consider:

1. create new API definitions in this same repo
2. editing the existing API definition to your needs

To learn more about how to build APIs for your managed control planes in Upbound, read the guide on [Upbound's docs](https://docs.upbound.io/).