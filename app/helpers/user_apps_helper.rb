module UserAppsHelper

  def legal_status_human_readable(status)
    {
        UserApp::LEGAL_STATUS_NO => "Нет",
        UserApp::LEGAL_STATUS_YES  => "Есть",
        UserApp::LEGAL_STATUS_LAWYER => "Адвокат"
    }[status]
  end

  def status_human_readable(status)
    statuses = []
    UserApp.all_statuses.each do |st, st_name|
      if st & status > 0
        statuses << t("user_app.status.#{st_name}")
      end
    end
    statuses.join(", ")
  end

  def social_accounts_readable(social_accounts)
    social_block = []

    social_accounts.each do |provider, profile_link|
      if profile_link.present?
        if profile_link[/^http:\/\//] || profile_link[/^https:\/\//]
          social_block << link_to(profile_link, profile_link) #полное отображение ссылок, чтобы оператор точно видел, куда переходит
        else
          social_block << "#{UserApp::SOCIAL_ACCOUNTS[provider.to_sym]}: #{profile_link}"
        end
      end
    end
    social_block.join(", <br>")
  end

  def social_account_placeholders(provider)
    {
        vk: "http://vk.com/<...>",
        fb: "https://www.facebook.com/<...> или /profile.php?id=<...>",
        twitter: "https://twitter.com/<...>",
        lj: "http://<...>.livejournal.com" ,
        ok: "http://www.odnoklassniki.ru/profile/<...>"
    }[provider]
  end

  def regions_hash
    regions = {}
    Region.adm_regions.each do |adm_region|
      regions[adm_region.id] = []
      adm_region.regions.each do |mun_region|
        regions[adm_region.id] << {id: mun_region.id, name: mun_region.name}
      end
    end
    regions
  end

end