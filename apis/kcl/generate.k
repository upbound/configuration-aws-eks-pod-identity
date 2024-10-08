import file
import yaml

_composition = {
    apiVersion: "apiextensions.crossplane.io/v1",
    kind: "Composition",
    metadata: {
        name: "kcl.xpodidentities.aws.platform.upbound.io",
        labels: {
            provider: "aws",
            function: "kcl",
        },
    },
    spec: {
        writeConnectionSecretsToNamespace: "upbound-system",
        compositeTypeRef: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "XPodIdentity"
        },
        mode: "Pipeline",
        pipeline: [
            {
                step: "kcl"
                functionRef: {
                    name: "crossplane-contrib-function-kcl"
                }
                input: {
                    apiVersion: "krm.kcl.dev/v1alpha1"
                    kind: "KCLRun"
                    spec: {
                        source = (file.read("apis/kcl/main.k"))
                    }
                }
            },
            {
                step: "automatically-detect-ready-composed-resources"
                functionRef: {
                    name: "crossplane-contrib-function-auto-ready"
                },
            }
        ]
    }
}

file.write("apis/kcl/composition.yaml", yaml.encode(_composition))
