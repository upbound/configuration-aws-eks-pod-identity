import models.io.upbound.awsm.eks.v1beta1 as eksv1beta1
import models.io.upbound.awsm.iam.v1beta1 as iamv1beta1

oxr = option("params").oxr # observed composite resource
_ocds = option("params").ocds # observed composed resources
_dxr = option("params").dxr # desired composite resource
dcds = option("params").dcds # desired composed resources

params = oxr.spec.parameters

_metadata = lambda name: str -> any {
    { annotations = { "krm.kcl.dev/composition-resource-name" = name }}
}

_defaults ={
    managementPolicies = params.managementPolicies or ["*"]
    if params.providerConfigName:
        providerConfigRef = {
            kind = "ProviderConfig"
            name = params.providerConfigName
        }
}

_items = [
    iamv1beta1.Role{
        metadata = _metadata("iamRole")
        spec = _defaults | {
            forProvider = {
                inlinePolicy = params.inlinePolicy
                permissionsBoundary = params.permissionBoundaryArn
                managedPolicyArns = params.managedPolicyArns
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
        metadata = _metadata("podIdentityAssociation")
        spec = _defaults | {
            forProvider = {
                region = params.region
                roleArnSelector: {
                    matchControllerRef: True
                }
                if params.clusterName: clusterName = params.clusterName
                if params.clusterNameRef: clusterNameRef = params.clusterNameRef
                if params.clusterNameSelector: clusterNameSelector = params.clusterNameSelector
                serviceAccount = params.serviceAccount.name
                namespace = params.serviceAccount.namespace
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

