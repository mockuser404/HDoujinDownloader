function Register()

    module.Name = 'LXHENTAI'
    module.Language = 'vn'
    module.Adult = true

    module.Domains.Add('lxmanga.*')
    module.Domains.Add('lxmanga.click')
    module.Domains.Add('lxmanga.ink')
    module.Domains.Add('lxmanga.life')
    module.Domains.Add('lxmanga.net')
    module.Domains.Add('lxmanga.online')

end

function GetInfo()

    -- Isolate the metadata div.

    dom = dom.SelectNode('(//div[div/div[contains(@class,"cover-frame")]])[1]')

    info.Title = dom.SelectValue('//li[@aria-current]//span')
    info.AlternativeTitle = dom.SelectValue('.//span[contains(text(),"Tên khác")]/following-sibling::span')
    info.Tags = dom.SelectValues('.//span[contains(text(),"Thể loại")]/following-sibling::span//a')
    info.Author = dom.SelectValues('.//span[contains(text(),"Tác giả")]/following-sibling::span//a')
    info.Translator = dom.SelectValues('.//span[contains(text(),"Nhóm dịch")]/following-sibling::span//a')
    info.Status = dom.SelectValues('.//span[contains(text(),"Tình trạng")]/following-sibling::a')
    info.Parody = dom.SelectValues('.//span[contains(text(),"Doujinshi")]/following-sibling::span//a')

    if(API_VERSION > 20240325) then
        info.ThumbnailUrl = dom.SelectValue('.//div[contains(@class,"cover")]//@style'):regex("url\\('([^']+)'\\)", 1)
    end

end

function GetChapters()

    for chapterNode in dom.SelectElements('//div[contains(.,"Danh sách chương")]//ul/a') do

        local chapterUrl = chapterNode.SelectValue('./@href')
        local chapterTitle = chapterNode.SelectValue('.//span[not(img) and last()]')

        chapters.Add(chapterUrl, chapterTitle)

    end

    chapters.Reverse()

end

function GetPages()

    pages.AddRange(dom.SelectValues('//img[contains(@class,"lazy")]/@src'))

    if(isempty(pages)) then
        pages.AddRange(dom.SelectValues('//div[@id="image-container"]//@data-src'))
    end

end
