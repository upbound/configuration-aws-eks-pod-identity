import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

_items = [
    metav1alpha1.E2ETest {
        metadata.name: "pod-identity"
        spec = {
            crossplane.autoUpgrade.channel: "Rapid"
            defaultConditions: ["Ready"]
            manifests: [
                platformawsv1alpha1.XPodIdentity {
                    apiVersion = "aws.platform.upbound.io/v1alpha1"
                    kind = "XPodIdentity"
                    metadata = {
                        name = "configuration-aws-eks-pod-identity"
                    }
                    spec = {
                        parameters = {
                            region = "us-west-2"
                            clusterNameSelector = {
                                matchLabels = {
                                    "crossplane.io/composite" = "configuration-aws-eks-pod-identity"
                                }
                            }
                            managedPolicyArns = [
                                "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
                            ]
                            inlinePolicy = [
                                {
                                    name = "default"
                                    policy = r"""{
                                        "Version": "2012-10-17",
                                        "Statement": [
                                            {
                                                "Action": [
                                                    "kms:Decrypt",
                                                    "kms:DescribeKey"
                                                ],
                                                "Effect": "Allow",
                                                "Resource": "*"
                                            }
                                        ]
                                    }
                                    """
                                }
                            ]
                            serviceAccount = {
                                name = "my-controller"
                                namespace = "kube-system"
                            }
                        }
                    }
                }
                platformawsv1alpha1.XEKS{
                    metadata = {
                        name = "configuration-aws-eks-pod-identity"
                    }
                    spec = {
                        parameters = {
                            id = "configuration-aws-eks-pod-identity"
                            region = "us-west-2"
                            version = "1.33"
                            nodes = {
                                count = 1
                                instanceType = "t3.small"
                            }
                        }
                        writeConnectionSecretToRef = {
                            name = "configuration-aws-eks-pod-identity-kubeconfig"
                            namespace = "upbound-system"
                        }
                    }
                }
                {
                    apiVersion = "aws.platform.upbound.io/v1alpha1"
                    kind = "XNetwork"
                    metadata = {
                        name = "configuration-aws-eks-pod-identity"
                    }
                    spec = {
                        parameters = {
                            id = "configuration-aws-eks-pod-identity"
                            region = "us-west-2"
                        }
                    }
                }

            ]
            extraResources: [
                # Define the provider configuration
                awsv1beta1.ProviderConfig{
                    metadata.name = "default"
                    spec = {
                        credentials = {
                            source = "Upbound"
                            upbound = {
                                webIdentity = {
                                    roleARN = "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                                }
                            }
                        }
                    }
                }
            ]
            skipDelete: False
            timeoutSeconds: 4500
        }
    }
]
items = _items
