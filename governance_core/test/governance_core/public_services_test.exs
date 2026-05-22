defmodule GovernanceCore.PublicServicesTest do
  use GovernanceCore.DataCase, async: false

  alias GovernanceCore.Payment.Payments
  alias GovernanceCore.PublicServices

  test "cv generator registers as a public callable payment service" do
    assert {:ok, service} = PublicServices.ensure_cv_generator_registered()

    assert service.slug == "cv-generator"
    assert service.endpoint_url == "https://cv.e-any.online/api/generate"
    assert service.price_per_request == 25

    fetched = Payments.get_service_by_slug("cv-generator")
    assert fetched.id == service.id
  end

  test "cv generator card exposes integration metadata without secrets" do
    card = PublicServices.cv_generator_card()

    assert card.slug == "cv-generator"
    assert card.embed_url == "https://cv.e-any.online/embed"
    assert "external websites" in card.callable_from
    refute inspect(card) =~ "vault://"
    refute inspect(card) =~ "secret"
  end
end
