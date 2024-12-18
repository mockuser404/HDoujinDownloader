function Register()

    module.Name = 'MANHWAS MEN'
    module.Language = 'English'
    module.Adult = true

    module.Domains.Add('manhwas.men')

end

function GetInfo()

    info.Title = dom.SelectValue('//h1')
    info.AlternativeTitle = dom.SelectValue('//h2')
    info.Summary = dom.SelectValue('//p[@class="sinopsis"]')
    info.Tags = dom.SelectValues('//*[@class="genres"]/span/a')
    info.Type = dom.SelectValues('//*[@class="meta"]/span[1]')
    info.Status = dom.SelectValues('//*[@class="meta"]/span[2]')

    if(info.Title:lower():trim():endswith("raw")) then
        info.Language = 'Korean'
    end

end

function GetChapters()

    for chapterNode in dom.SelectElements('//*[@id="tioanime"]//section[2]/ul/li/a') do

        local chapterUrl = chapterNode.SelectValue('@href')
        local chapterTitle = chapterNode.SelectValue('./div/p/span')

        chapters.Add(chapterUrl, chapterTitle)

    end

    chapters.Reverse()

end

function GetPages()
    pages.AddRange(dom.SelectValues('//div[@id="chapter_imgs"]//img/@src'))
end
