function Register()

    module.Name = 'MangaKatana'
    module.Language = 'English'

    module.Domains.Add('mangakatana.com', 'MangaKatana')

end

function GetInfo()

    info.Title = dom.SelectValue('//h1')
    info.AlternativeTitle = dom.SelectValue('//div[contains(@class,"alt_name")]'):split(';')
    info.Author = dom.SelectValues('//div[contains(@class,"authors")]/a')
    info.Tags = dom.SelectValues('//div[contains(@class,"genres")]/a')
    info.Status = dom.SelectValue('//div[contains(@class,"status")]')
    info.Summary = dom.SelectValue('//div[contains(@class,"summary")]/p')

end

function GetChapters()

    chapters.AddRange(dom.SelectElements('//div[contains(@class,"chapters")]//a'))

    chapters.Reverse()

end

function GetPages()

    -- Pages are stored in the "ytaw" array, with the URLs revsersed.

    local pagesArray = tostring(dom):regex('var\\s*ytaw=\\s*(\\[.+?\\])', 1)
    local pagesJson = Json.New(pagesArray)

    for obfuscatedPageUrl in pagesJson do

        local pageUrl = tostring(obfuscatedPageUrl):reverse()

        -- Skip the OpenSocial proxy.

        pageUrl = pageUrl:after('&url=')

        -- The webpage does this.
        
        if(pageUrl:contains('webp?v=')) then
            pageUrl = pageUrl:before('?v=')
        end

        pages.Add(pageUrl)

    end

end
