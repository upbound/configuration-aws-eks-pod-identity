import models.io.upbound.aws.eks.v1beta1 as eksv1beta1
import models.io.upbound.aws.iam.v1beta1 as iamv1beta1

oxr = option("params").oxr # observed composite resource
_ocds = option("params").ocds # observed composed resources
_dxr = option("params").dxr # desired composite resource
dcds = option("params").dcds # desired composed resources

xrName = option("params")?.oxr?.metadata.name
region = option("params")?.oxr?.spec.parameters.region or ""
id = option("params")?.oxr?.spec.parameters.id or ""

_metadata = lambda name: str -> any {
    { annotations = { "krm.kcl.dev/composition-resource-name" = name }}
}

_defaults ={
    deletionPolicy = option("params")?.oxr?.spec.parameters.deletionPolicy or "Delete"
    providerConfigRef.name = option("params")?.oxr?.spec.parameters.providerConfigName or "default"
}

_items = []

inlinePolicy = option("params")?.oxr?.spec.parameters.inlinePolicy or False
permissionBoundaryArn = option("params")?.oxr?.spec.parameters.permissionsBoundaryArn or False
managedPolicyArns = option("params")?.oxr?.spec.parameters.managedPolicyArns or False

_items += [
    iamv1beta1.Role{
        metadata = _metadata("iamRole")
        spec = _defaults | {
            forProvider = {
                if inlinePolicy:
                    inlinePolicy = inlinePolicy
                if permissionBoundaryArn:
                    permissionsBoundary = permissionBoundaryArn
                if managedPolicyArns:
                    managedPolicyArns = managedPolicyArns
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
]

clusterName = option("params")?.oxr?.spec.parameters.clusterName or False
clusterNameRef = option("params")?.oxr?.spec.parameters.clusterNameRef or False
clusterNameSelector = option("params")?.oxr?.spec.parameters.clusterNameSelector or False
serviceAccount = option("params")?.oxr?.spec.parameters.serviceAccount.name or False
namespace = option("params")?.oxr?.spec.parameters.serviceAccount.namespace or False

_items += [
    eksv1beta1.PodIdentityAssociation{
        apiVersion = "eks.aws.upbound.io/v1beta1"
        kind = "PodIdentityAssociation"
        metadata = _metadata("podIdentityAssociation")
        spec = _defaults | {
            forProvider = {
                region = region
                roleArnSelector: {
                    matchControllerRef: True
                }
                if clusterName:
                    clusterName = clusterName
                if clusterNameRef:
                    clusterNameRef = clusterNameRef
                if clusterNameSelector:
                    clusterNameSelector = clusterNameSelector
                serviceAccount = serviceAccount
                namespace = namespace
            }
        }
    }
]

observedClusterName = _ocds.podIdentityAssociation?.Resource?.status?.atProvider?.clusterName

_dxr.status = {
    podIdentity = {
        clusterName = observedClusterName
        roleArn = _ocds.iamRole?.Resource?.status?.atProvider?.arn
    }
}

_items += [_dxr]

items = _items

