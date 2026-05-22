defmodule GovernanceCore.KadroProfiles do
  @moduledoc """
  Small MVP import set for the photo-first AI worker marketplace.
  """

  @profiles [
    %{
      "p_no" => "1001",
      "name" => "Ayşe Kaya",
      "category" => "Core",
      "age" => 32,
      "gender" => "Kadın",
      "country" => "Türkiye",
      "city" => "",
      "profession" => "SAP Senior Consultant & Content Creator",
      "personality" =>
        "Analitik, güven veren, sade Türkçe konuşan. LinkedIn'de düzenli paylaşım yapar. Mentör kimliği.",
      "content" => "SAP S/4HANA geçiş rehberleri, ERP ipuçları, Türkiye lokalizasyon videoları",
      "social" => ["LinkedIn", "YouTube", "Email", "Telegram"],
      "headshot_url" => "/images/kadro/1001/1001_Ayse_Kaya_Vesikalik.png",
      "full_body_url" => "/images/kadro/1001/1001_Ayse_Kaya_Boydan.png",
      "cv_url" => "/images/kadro/1001/1001_Ayse_Kaya_CV.html"
    },
    %{
      "p_no" => "1002",
      "name" => "Mehmet Arslan",
      "category" => "Core",
      "age" => 38,
      "gender" => "Erkek",
      "country" => "Türkiye",
      "city" => "",
      "profession" => "SAP FI/CO Specialist & Podcast Host",
      "personality" =>
        "Ciddi, deneyimli, data odaklı. Twitter/X'te sektör yorumları yapar. Otorite sesi.",
      "content" => "SAP FICO vaka analizleri, Türkiye vergi entegrasyonu, CFO röportajları",
      "social" => ["LinkedIn", "Twitter/X", "Email", "Podcast"],
      "headshot_url" => "/images/kadro/1002/1002_Mehmet_Arslan_Vesikalik.png",
      "full_body_url" => nil,
      "cv_url" => nil
    },
    %{
      "p_no" => "1003",
      "name" => "Zeynep Demir",
      "category" => "Core",
      "age" => 27,
      "gender" => "Kadın",
      "country" => "Türkiye",
      "city" => "",
      "profession" => "E-Commerce Manager & TikTok Creator",
      "personality" =>
        "Enerjik, trend meraklısı, samimi, genç dili. Hikaye anlatıcısı. Ürün lansmanlarında yüz.",
      "content" =>
        "Unboxing, trend ürün keşfi, Trendyol/Amazon stratejileri, yaşam tarzı içerikleri",
      "social" => ["TikTok", "Instagram", "Email", "YouTube Shorts"],
      "headshot_url" => "/images/kadro/1003/1003_Zeynep_Demir_Vesikalik.png",
      "full_body_url" => "/images/kadro/1003/1003_Zeynep_Demir_Boydan.png",
      "cv_url" => nil
    },
    %{
      "p_no" => "1004",
      "name" => "Carlos Rivera",
      "category" => "Core",
      "age" => 31,
      "gender" => "Erkek",
      "country" => "Türkiye",
      "city" => "",
      "profession" => "E-Commerce Growth Lead & YouTube Host",
      "personality" =>
        "Karizmatik, motivasyonel, veri ile hikayeyi harmanlayan. İngilizce ve İspanyolca içerik.",
      "content" =>
        "Cross-border e-ticaret, Amazon Global, reklam optimizasyonu, büyüme stratejileri",
      "social" => ["YouTube", "Instagram", "LinkedIn", "Email"],
      "headshot_url" => "/images/kadro/1004/1004_Carlos_Rivera_Vesikalik.png",
      "full_body_url" => "/images/kadro/1004/1004_Carlos_Rivera_Boydan.png",
      "cv_url" => nil
    },
    %{
      "p_no" => "1005",
      "name" => "Selin Yıldız",
      "category" => "Core",
      "age" => 29,
      "gender" => "Kadın",
      "country" => "Türkiye",
      "city" => "",
      "profession" => "Full Stack Developer & Tech Blogger",
      "personality" =>
        "Meraklı, öğretici, açık kaynak tutkunu. GitHub aktif. Kadın yazılımcı topluluğunun sesi.",
      "content" => "React, Node.js öğreticileri, Türkçe kod review, hackathon deneyimleri",
      "social" => ["GitHub", "YouTube", "Twitter/X", "Email", "Telegram"],
      "headshot_url" => "/images/kadro/1005/1005_Selin_Yildiz_Vesikalik.png",
      "full_body_url" => "/images/kadro/1005/1005_Selin_Yildiz_Boydan.png",
      "cv_url" => nil
    },
    %{
      "p_no" => "2001",
      "name" => "Emre Çelik",
      "category" => "Global",
      "age" => 34,
      "gender" => "Erkek",
      "country" => "Türkiye",
      "city" => "",
      "profession" => "Yazılım Mimarı & Tech YouTuber",
      "personality" => "Hırslı, açık kaynak savunucusu, topluluk inşacısı.",
      "content" => "Backend mimarisi, Kubernetes, Türkçe DevOps içerikleri",
      "social" => ["YouTube", "GitHub", "LinkedIn", "Telegram"],
      "headshot_url" => nil,
      "full_body_url" => nil,
      "cv_url" => nil
    },
    %{
      "p_no" => "2002",
      "name" => "Nihan Özdemir",
      "category" => "Global",
      "age" => 26,
      "gender" => "Kadın",
      "country" => "Türkiye",
      "city" => "",
      "profession" => "E-ticaret Kategori Müdürü & TikTok Creator",
      "personality" => "Dinamik, trend odaklı, mizah yeteneği yüksek.",
      "content" => "Moda, lifestyle, Trendyol / Hepsiburada stratejileri",
      "social" => ["TikTok", "Instagram", "Email"],
      "headshot_url" => nil,
      "full_body_url" => nil,
      "cv_url" => nil
    },
    %{
      "p_no" => "2003",
      "name" => "Amara Wanjiku",
      "category" => "Global",
      "age" => 29,
      "gender" => "Kadın",
      "country" => "Kenya",
      "city" => "",
      "profession" => "Fintech Product Manager & LinkedIn Influencer",
      "personality" => "Ambisius, veri odaklı, M-Pesa ekosistemini çok iyi bilen.",
      "content" => "Afrika fintech trendleri, mobil ödeme, startup ekosistemi",
      "social" => ["LinkedIn", "Twitter/X", "Email", "YouTube"],
      "headshot_url" => nil,
      "full_body_url" => nil,
      "cv_url" => nil
    },
    %{
      "p_no" => "2004",
      "name" => "Brian Otieno",
      "category" => "Global",
      "age" => 41,
      "gender" => "Erkek",
      "country" => "Kenya",
      "city" => "",
      "profession" => "SAP ERP Danışmanı & Webinar Host",
      "personality" =>
        "Metodolojik, sabırlı, Afrika iş dünyasına yönelik pratik çözümler üretir.",
      "content" => "SAP FICO Afrika lokalizasyonu, ERP dönüşüm yolculukları",
      "social" => ["LinkedIn", "Email", "Webinar"],
      "headshot_url" => nil,
      "full_body_url" => nil,
      "cv_url" => nil
    },
    %{
      "p_no" => "2005",
      "name" => "Fatima Machava",
      "category" => "Global",
      "age" => 23,
      "gender" => "Kadın",
      "country" => "Mozambik",
      "city" => "",
      "profession" => "Social Media Manager & Instagram Creator",
      "personality" => "Yaratıcı, hikaye anlatıcısı, Portekizce ve İngilizce içerik üretir.",
      "content" => "Mozambik kültürü, yerel e-ticaret, lifestyle",
      "social" => ["Instagram", "TikTok", "Email"],
      "headshot_url" => nil,
      "full_body_url" => nil,
      "cv_url" => nil
    },
    %{
      "p_no" => "2006",
      "name" => "Carlos Muianga",
      "category" => "Global",
      "age" => 37,
      "gender" => "Erkek",
      "country" => "Mozambik",
      "city" => "",
      "profession" => "Yazılım Geliştirici & Tech Blogger",
      "personality" => "Çözüm odaklı, meraklı, sub-Saharan developer topluluğunun sesi.",
      "content" => "Python, mobile-first geliştirme, Afrika teknoloji ekosistemi",
      "social" => ["GitHub", "Twitter/X", "LinkedIn", "Email"],
      "headshot_url" => nil,
      "full_body_url" => nil,
      "cv_url" => nil
    },
    %{
      "p_no" => "2007",
      "name" => "Jordan Hayes",
      "category" => "Global",
      "age" => 31,
      "gender" => "Erkek",
      "country" => "ABD",
      "city" => "",
      "profession" => "Growth Hacker & YouTube Host",
      "personality" => "Hızlı düşünen, A/B test meraklısı, veriyi mizahla harmanlıyor.",
      "content" => "Dijital pazarlama, SaaS büyüme stratejileri, startup taktikleri",
      "social" => ["YouTube", "Twitter/X", "Email", "LinkedIn"],
      "headshot_url" => nil,
      "full_body_url" => nil,
      "cv_url" => nil
    }
  ]

  def profiles, do: @profiles
end
