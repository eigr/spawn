defmodule Operator.K8S.Resources.Ingress do
  @behaviour Operator.K8S.Manifest

  alias Operator.K8S.Ingress.{Ambassador, Glbc, Gloo, Istio, Nginx, Traefik}

  @impl true
  def manifest(ns, name, params) do
    ingress_params = params["expose"]["ingress"]
    className = ingress_params["className"]
    host = ingress_params["host"]
    path_type = get_path_type(className, ingress_params)

    ingress = %{
      "apiVersion" => "networking.k8s.io/v1",
      "kind" => "Ingress",
      "metadata" => %{},
      "spec" => %{}
    }

    ingress =
      case get_annotation_for_ingress(className, ingress_params) do
        {:ok, annotations} ->
          %{
            ingress
            | "metadata" => %{
                "annotations" => annotations,
                "labels" => %{
                  "functions.eigr.io/controller.version" =>
                    "#{to_string(Application.spec(:eigr_functions_controller, :vsn))}",
                  "functions.eigr.io/wormhole.gate.earth.status" => "open"
                },
                "name" => "#{name}-ingress",
                "namespace" => ns
              }
          }

        {:nothing, _} ->
          ingress
      end

    ingress =
      case get_tls(ingress_params) do
        {:ok, tls} ->
          %{
            ingress
            | "spec" => %{
                "tls" => [tls],
                "ingressClassName" => get_ingress_class(ingress_params),
                "rules" => [
                  %{
                    "host" => host,
                    "http" => %{
                      "paths" => [
                        %{
                          "path" => "/",
                          "pathType" => path_type,
                          "backend" => %{
                            "service" => %{
                              "name" => "#{name}-svc",
                              "port" => %{
                                "name" => "proxy"
                              }
                            }
                          }
                        },
                        %{
                          "path" => "/api",
                          "pathType" => path_type,
                          "backend" => %{
                            "service" => %{
                              "name" => "#{name}-svc",
                              "port" => %{
                                "name" => "http"
                              }
                            }
                          }
                        }
                      ]
                    }
                  }
                ]
              }
          }

        {:nothing, _} ->
          %{
            ingress
            | "spec" => %{
                "ingressClassName" => get_ingress_class(ingress_params),
                "rules" => [
                  %{
                    "host" => host,
                    "http" => %{
                      "paths" => [
                        %{
                          "path" => "/",
                          "pathType" => path_type,
                          "backend" => %{
                            "service" => %{
                              "name" => "#{name}-svc",
                              "port" => %{
                                "name" => "proxy"
                              }
                            }
                          }
                        },
                        %{
                          "path" => "/api",
                          "pathType" => path_type,
                          "backend" => %{
                            "service" => %{
                              "name" => "#{name}-svc",
                              "port" => %{
                                "name" => "http"
                              }
                            }
                          }
                        }
                      ]
                    }
                  }
                ]
              }
          }
      end

    ingress
  end

  defp get_tls(params) do
    ingressClass = params["className"]

    case ingressClass do
      "ambassador" ->
        Ambassador.get_tls_secret(params)

      "glbc" ->
        Glbc.get_tls_secret(params)

      "gloo" ->
        Gloo.get_tls_secret(params)

      "istio" ->
        Istio.get_tls_secret(params)

      "nginx" ->
        Nginx.get_tls_secret(params)

      "traefik" ->
        Traefik.get_tls_secret(params)

      _ ->
        raise "Unknown ingress class: #{ingressClass}"
    end
  end

  defp get_ingress_class(params) do
    ingressClass = params["className"]

    case ingressClass do
      "ambassador" ->
        Ambassador.get_class(params)

      "glbc" ->
        Glbc.get_class(params)

      "gloo" ->
        Gloo.get_class(params)

      "istio" ->
        Istio.get_class(params)

      "nginx" ->
        Nginx.get_class(params)

      "traefik" ->
        Traefik.get_class(params)

      _ ->
        raise "Unknown ingress class: #{ingressClass}"
    end
  end

  defp get_annotation_for_ingress(ingressClass, ingress) do
    case ingressClass do
      "ambassador" ->
        Ambassador.get_annotations(ingress)

      "glbc" ->
        Glbc.get_annotations(ingress)

      "gloo" ->
        Gloo.get_annotations(ingress)

      "istio" ->
        Istio.get_annotations(ingress)

      "nginx" ->
        Nginx.get_annotations(ingress)

      "traefik" ->
        Traefik.get_annotations(ingress)

      _ ->
        raise "Unknown ingress class: #{ingressClass}"
    end
  end

  defp get_path_type(ingressClass, ingress) do
    case ingressClass do
      "ambassador" ->
        Ambassador.get_path_type(ingress)

      "glbc" ->
        Glbc.get_path_type(ingress)

      "gloo" ->
        Gloo.get_path_type(ingress)

      "istio" ->
        Istio.get_path_type(ingress)

      "nginx" ->
        Nginx.get_path_type(ingress)

      "traefik" ->
        Traefik.get_path_type(ingress)

      _ ->
        raise "Unknown ingress class: #{ingressClass}"
    end
  end
end
