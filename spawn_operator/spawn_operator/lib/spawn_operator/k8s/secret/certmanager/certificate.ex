defmodule SpawnOperator.K8s.Secret.CertManager.Certificate do
  @moduledoc """
  This module generates CertManager Certificate to use with Erlang Dist in tls mode.

  Resource like this:
    ---
    apiVersion: spawn.eigr.io/v1
    kind: ActorSystem
    metadata:
      name: spawn-system # Mandatory. Name of the state store
      namespace: default # Optional. Default namespace is "default"
    spec:
      cluster: # Optional
        kind: erlang # Optional. Default erlang. Possible values [erlang | quic]
        cookie: default-c21f969b5f03d33d43e04f8f136e7682 # Optional. Only used if kind is erlang
        tls:
          secretName: spawn-system-tls-secret
          certManager:
            enabled: true # Default false
            issuerName: spawn-system-issuer # You must create an Issuer previously according to certmanager documentation

  Will generate the following certificate:
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: spawn-system-certificate
    spec:
      encodeUsagesInRequest: false
      isCA: false
      issuerRef:
        name: spawn-system-issuer
      secretName: spawn-system-tls-secret
  """
  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(resource), do: gen_certificate(resource)

  defp gen_certificate(
         %{
           system: system,
           namespace: ns,
           name: _name,
           params: params,
           labels: _labels,
           annotations: _annotations
         } = _resource
       ) do
    _cluster_params = Map.get(params, "cluster", %{})

    %{
      "apiVersion" => "cert-manager.io/v1",
      "kind" => "Certificate",
      "metadata" => %{
        "name" => "#{system}-certificate",
        "namespace" => ns
      },
      "spec" => %{
        "encodeUsagesInRequest" => false,
        "isCA" => false,
        "issuerRef" => %{
          "name" => ""
        },
        "secretName" => ""
      }
    }
  end
end
