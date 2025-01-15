defmodule SpawnOperator.K8s.System.Secret.CertManager.Certificate do
  @moduledoc """
  This module generates CertManager Certificate to use with Erlang Dist in tls mode.

  Resource like this:
  ---
  apiVersion: spawn-eigr.io/v1
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
          # default is Issuer. Possible values are [Issuer | ClusterIssuer]
          kind: Issuer
          # Optional. Default to eigr
          subject: "eigr"
          # Optional. Default to 360h
          duration: "2160h"
          # This is optional since cert-manager will default to this value however
          # if you are using an external issuer, change this to that issuer group.
          group: cert-manager.io

  Will generate the following certificate:
  ---
  apiVersion: cert-manager.io/v1
  kind: Certificate
  metadata:
    name: spawn-system-certificate
    namespace: default
  spec:
    secretName: spawn-system-tls-secret
    isCA: false
    duration: 2160h
    encodeUsagesInRequest: false
    subject:
      organizations:
        - eigr
    dnsNames:
      - system-spawn-system.svc.cluster.local
    issuerRef:
      name: spawn-system-issuer
      kind: Issuer
      group: cert-manager.io
  """
  @behaviour SpawnOperator.K8s.Manifest

  # 15d
  @default_duration "360h"
  @default_group "cert-manager.io"
  @default_issuer_kind "Issuer"
  @default_subject "eigr"

  @impl true
  def manifest(resource, opts \\ []), do: gen_certificate(resource, opts)

  defp gen_certificate(
         %{
           system: system,
           namespace: ns,
           name: name,
           params: params,
           labels: _labels,
           annotations: _annotations
         } = _resource,
         opts
       ) do
    tls = Map.get(params, "cluster", %{}) |> Map.get("tls", %{})
    certmanager = Map.get(tls, "certManager", %{enabled: false})

    case certmanager.enabled do
      true ->
        build_certificate(system, ns, name, certmanager, opts)

      _ ->
        %{}
    end
  end

  defp build_certificate(system, ns, name, certmanager, opts) do
    dns_names = Keyword.get(opts, :dns_names, ["system-#{system}.#{system}.svc.cluster.local"])
    duration = Map.get(certmanager, "duration", @default_duration)
    group = Map.get(certmanager, "group", @default_group)
    issuer_kind = Map.get(certmanager, "kind", @default_issuer_kind)
    issuer_name = Map.fetch!(certmanager, "issuerName")
    secret_name = Map.fetch!(certmanager, "secretName")
    subject = Map.get(certmanager, "subject", @default_subject)

    %{
      "apiVersion" => "cert-manager.io/v1",
      "kind" => "Certificate",
      "metadata" => %{
        "name" => "#{system}-cert",
        "namespace" => String.downcase(name)
      },
      "spec" => %{
        "secretName" => secret_name,
        "duration" => duration,
        "dnsNames" => dns_names,
        "subject" => %{
          "organizations" => [subject]
        },
        "encodeUsagesInRequest" => false,
        "isCA" => false,
        "issuerRef" => %{
          "name" => issuer_name,
          "kind" => issuer_kind,
          "group" => group
        }
      }
    }
  end
end
