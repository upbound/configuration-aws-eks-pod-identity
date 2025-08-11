
import models.io.upbound.aws.eks.v1beta1 as eksv1beta1
import models.io.upbound.aws.iam.v1beta1 as iamv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: ""
        spec= {
            assertResources: [
                platformawsv1alpha1.XPodIdentity{
                    metadata = {
                        name = "configuration-aws-eks-pod-identity"
                    }
                    spec = {
                        parameters = {
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
                            managedPolicyArns = [
                                "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
                            ]
                            region = "us-west-2"
                            serviceAccount = {
                                name = "my-controller"
                                namespace = "kube-system"
                            }
                        }
                    }
                    status = {
                        podIdentity = {
                            clusterName = "observed-dynamic-cluster-name" # see observedResources setup below
                        }
                        conditions = [
                            {
                                lastTransitionTime = "2024-01-01T00:00:00Z"
                                message = "Unready resources: iamRole, podIdentityAssociation"
                                reason = "Creating"
                                status = "False"
                                $type = "Ready"
                            }
                        ]
                    }
                }
                iamv1beta1.Role{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "iamRole"
                        }
                        generateName = "configuration-aws-eks-pod-identity-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-eks-pod-identity"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XPodIdentity"
                                name = "configuration-aws-eks-pod-identity"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        deletionPolicy = "Delete"
                        forProvider = {
                            assumeRolePolicy = r"""{
    "Version":"2012-10-17",
    "Statement":[
        {
        "Sid":"AllowEksAuthToAssumeRoleForPodIdentity",
        "Effect":"Allow",
        "Principal":{
            "Service":"pods.eks.amazonaws.com"
        },
        "Action":[
            "sts:AssumeRole",
            "sts:TagSession"
        ]
        }
    ]
}"""
                        }
                    }
                }
                eksv1beta1.PodIdentityAssociation{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "podIdentityAssociation"
                        }
                        generateName = "configuration-aws-eks-pod-identity-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-eks-pod-identity"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XPodIdentity"
                                name = "configuration-aws-eks-pod-identity"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        deletionPolicy = "Delete"
                        forProvider = {
                            clusterNameSelector = {
                                matchLabels = {
                                    "crossplane.io/composite" = "configuration-aws-eks-pod-identity"
                                }
                            }
                            namespace = "kube-system"
                            region = "us-west-2"
                            roleArnSelector = {
                                matchControllerRef = True
                            }
                            serviceAccount = "my-controller"
                        }
                        providerConfigRef = {
                            name = "default"
                        }
                    }
                }
            ]
            compositionPath: "apis/composition.yaml"
            xrPath: "examples/pod-identity-xr.yaml"
            xrdPath: "apis/definition.yaml"
            timeoutSeconds: 60
            observedResources= [
                eksv1beta1.PodIdentityAssociation{
                    metadata.annotations = {
                        "crossplane.io/composition-resource-name" = "podIdentityAssociation"
                    }
                    spec = {
                        forProvider = {
                            clusterNameSelector = {
                                matchControllerRef: True
                            }
                            region = "us-west-2"
                        }
                    }
                    status = {
                        atProvider = {
                            clusterName: "observed-dynamic-cluster-name"
                        }
                    }
                }
            ]
            validate: False
        }
    }
]
items= _items
