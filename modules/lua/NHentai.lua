function Register()

    module.Name = 'nhentai'
    module.Adult = true

    module.Domains.Add('nhentai.net')

    module.Domains.Add('3hentai.net', '3hentai')
    module.Domains.Add('es.3hentai.net', '3hentai')
    module.Domains.Add('fra.3hentai.net', '3hentai')
    module.Domains.Add('hitomila.to', 'Hitomila')
    module.Domains.Add('it.3hentai.net', '3hentai')
    module.Domains.Add('nhentai.to')
    module.Domains.Add('nhentai.uk')
    module.Domains.Add('nhentai.xxx')
    module.Domains.Add('pt.3hentai.net', '3hentai')
    module.Domains.Add('ru.3hentai.net', '3hentai')
    module.Domains.Add('simplyhentai.org', 'Simply Hentai')

    module.Settings.AddCheck('Use pretty titles', false)
        .WithToolTip('Use shorter titles with the artist, series, and language information removed.')

end

local function IsGalleryUrl()

    return url:contains('/g/') or
        url:contains('/d/') -- 3hentai.net

end

local function GetGalleryId()

    -- 3hentai.net uses "/d/" instead of "/g/"

    return url:regex('\\/[gd]\\/(\\d+)', 1)

end

local function GetPrettyTitle()

    local prettyTitle = dom.SelectValue('//span[contains(@class,"pretty")]')

    -- 3hentai.net

    if(isempty(prettyTitle)) then
        prettyTitle = dom.SelectValue('//span[contains(@class,"middle-title")]')
    end

    -- nhentai.uk

    if(isempty(prettyTitle)) then
        prettyTitle = RegexReplace(dom.SelectValue('//div[@id="bigcontainer"]//h1'):trim(), '(?i)(?:^Nhentai|hentai$)', '')
    end

    return prettyTitle

end

local function GetTagsFromTagGroup(groupName)

    local tags = dom.SelectValues('//div[contains(@class, "tag-container") and contains(text(), "'..groupName..'")]//span[@class="name"]')

    -- For sites using the old nhentai theme, we'll need to get the tags differently.

    if(isempty(tags)) then
        tags = dom.SelectValues('//div[contains(@class, "tag-container") and contains(text(), "'..groupName..'")]//a')
    end

    return tags

end

local function EnsureOnGalleryPage()

    local backToGalleryUrl = dom.SelectValue('//*[contains(@class,"back-to-gallery") or contains(@class,"go-back")]//@href')

    if(not isempty(backToGalleryUrl)) then

        local src = http.Get(backToGalleryUrl)
        dom = Dom.New(src)

    end

end

local function EnqueueAllGalleries(dom)

    for galleryUrl in dom.SelectValues('//div[contains(@class,"container")][last()]//div[contains(@class,"gallery")]/a/@href') do
        Enqueue(galleryUrl)
    end

end

function GetInfo()

    if(IsGalleryUrl()) then

        EnsureOnGalleryPage()

        -- Get the gallery's title.

        if(toboolean(module.Settings['Use pretty titles'])) then
            info.Title = GetPrettyTitle()
        end

        if(isempty(info.Title)) then -- nhentai.uk
            info.Title = dom.SelectValue('//div[@id="info"]/h1')
        end

        if(isempty(info.Title)) then
            info.Title = dom.SelectValue('//h1')
        end

        -- Fall back to the gallery ID if we can't get a title.

        if(isempty(info.Title)) then
            info.Title = GetGalleryId()
        end

        info.OriginalTitle = dom.SelectValue('//div[@id="info"]/h2')

        -- Get the gallery's tags.

        info.Tags = GetTagsFromTagGroup('Tags')
        info.Circle = tostring(GetTagsFromTagGroup('Groups')):title()
        info.Artist = tostring(GetTagsFromTagGroup('Artists')):title()
        info.Parody = tostring(GetTagsFromTagGroup('Parodies')):title()
        info.Characters = GetTagsFromTagGroup('Characters')
        info.Language = GetTagsFromTagGroup('Languages')
        info.Type = GetTagsFromTagGroup('Categories')

    else

        -- The user added their favorites, a tag, or a search URL.

        info.Ignore = true

        local maxScrapingDepth = global.GetSetting('Downloads.MaxScrapingDepth')

        if(isempty(maxScrapingDepth)) then
            maxScrapingDepth = 1
        end

        local depth = 0

        for page in Paginator.New(http, dom, '//section[contains(@class,"pagination")]/a[contains(@class,"next")]/@href') do

            EnqueueAllGalleries(page)

            depth = depth + 1

            if(depth >= tonumber(maxScrapingDepth)) then
                break
            end

        end

    end

end

function GetPages()

    EnsureOnGalleryPage()

    -- Get the thumbnail URLs.

    local thumbnailUrls = dom.SelectValues('//div[@id="thumbnail-container"]//img/@data-src')

    if(isempty(thumbnailUrls)) then -- 3hentai.net
        thumbnailUrls = dom.SelectValues('//div[@id="thumbnail-gallery"]//img/@data-src')
    end

    if(isempty(thumbnailUrls)) then -- simplyhentai.org
        thumbnailUrls = dom.SelectValues('//div[@class="thumb-container"]//img/@src')
    end

    -- Convert the thumbnail URLs to full image URLs.

    for thumbnailUrl in thumbnailUrls do

        local fullImageUrl = thumbnailUrl

        -- Adjust the image server from the thumbnail server (t1) to the image server (i1).

        if(module.Domain ~= 'nhentai.to') then
            fullImageUrl = RegexReplace(fullImageUrl, '\\/\\/t(\\d?)\\.', '//i$1.')
        end

        -- Remove the thumbnail prefix from the file name.

        fullImageUrl = RegexReplace(fullImageUrl, '(\\d+)t(.+?)$', '$1$2')

        -- Newer galleries on NHentai will have ".webp" appended to the original file extension (e.g. ".jpg.webp").
        -- We need to strip the extraneous file extension.

        fullImageUrl = RegexReplace(fullImageUrl, "\\.(jpg|png|webp)\\.webp$", ".$1")

        pages.Add(fullImageUrl)

    end

end

function Login()

    if(isempty(http.Cookies)) then

        local domain = module.Domain
        local loginUrl = 'https://' .. domain .. '/login/'

        http.Headers['Origin'] = 'https://' .. module.Domain
        http.Headers['Referer'] = 'https://' .. module.Domain .. '/login/?next=/'

        local dom = Dom.New(http.Get(loginUrl))

        http.PostData.Add('username_or_email', username)
        http.PostData.Add('password', password)
        http.PostData.Add('csrfmiddlewaretoken', dom.SelectValue('//input[@name="csrfmiddlewaretoken"]/@value'))
        http.PostData.Add('next', '/')

        local response = http.PostResponse(loginUrl)

        if(not response.Cookies.Contains('sessionid')) then
            Fail(Error.LoginFailed)
        end

        global.SetCookies(response.Cookies)

    end

end
