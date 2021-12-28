function Register()

    module.Name = 'Lezhin Comics'
    module.Language = 'en'
    module.Type = 'webtoon'

    module.Domains.Add('lezhinus.com')

end

function GetInfo()

    local json = GetComicJson()

    info.Title = json.SelectValue('display.title')
    info.Summary = json.SelectValue('display.synopsis')
    info.Artist = json.SelectValues('artists[*].name')
    info.Status = json.SelectValue('state')
    info.Tags = json.SelectValues('properties.tags[*]')

end

function GetChapters()

    local baseUrl = StripParameters(url:trim('/')) .. '/'
    local json = GetComicJson()

    for episodeNode in json.SelectTokens('episodes[*]') do

        local episodeUrl = baseUrl .. episodeNode.SelectValue('name')
        local episodeTitle = episodeNode.SelectValue('display.title')

        chapters.Add(episodeUrl, episodeTitle)

    end

    chapters.Reverse()

end

function GetPages()

    local json = GetEpisodeJson()

    local cdnUrl = dom.SelectValue('//script[contains(.,"contentsCdnUrl")]'):regex("contentsCdnUrl:\\s*'([^']+)'", 1)
    local scrollPaths = json.SelectValues('data.extra.episode.scrollsInfo[*].path')
    local quality = 40
    local signedData = GetSignedDataJson(json, quality)
    local policy = signedData.SelectValue('data.Policy')
    local signature = signedData.SelectValue('data.Signature')
    local keyPairId = signedData.SelectValue('data.Key-Pair-Id')

    for scrollPath in scrollPaths do
        pages.Add(cdnUrl .. '/v2' .. scrollPath .. '.jpg?purchased=true&q=' .. quality .. '&Policy=' .. policy .. '&Signature=' .. signature .. '&Key-Pair-Id=' .. keyPairId)
    end

end

function Login()

    if(not http.Cookies.Contains('REMEMBER')) then

        local endpoint = 'https://www.'.. module.Domain .. '/en/login?redirect=%2Fen'
        local dom = Dom.New(http.Get(endpoint))
        
        http.PostData['utf8'] = '✓'
        http.PostData['authenticity_token'] = dom.SelectValue('//input[@name="authenticity_token"]/@value')
        http.PostData['redirect'] = '/en'
        http.PostData['username'] = username
        http.PostData['password'] = password
        http.PostData['remember_me'] = 'on'

        local response = http.PostResponse(endpoint)

        if(not http.Cookies.Contains('REMEMBER')) then
            Fail(Error.LoginFailed)
        end

        -- Workaround for HDD storing the wrong RSESSION cookie after logging in.
        -- There will be two, one associated with www.lezhinus.com (the correct one) and another associated with lezhinus.com.

        local cookieDict = Dict.New()

        for cookie in response.Cookies do

            if(not cookieDict.ContainsKey(cookie.Name)) then
                cookieDict[cookie.Name] = cookie.Content
            end

        end

        for cookie in cookieDict.Keys do
            global.SetCookie(module.Domain, cookie, cookieDict[cookie])
        end

    end

end

function GetApiUrl()

    return 'https://www.lezhin.com/lz-api/v2/'

end

function GetComicJson()

    local script = dom.SelectValue('//script[contains(.,"__LZ_PRODUCT__ ")]')
    local productJson = script:regex('\\bproduct:\\s*({.+?}),\\s', 1)

    return Json.New(productJson)

end

function GetEpisodeJson()

    SetHttpHeaders()

    local contentSlug = url:regex('\\/comic\\/([^\\/]+)', 1)
    local episodeSlug = url:regex('\\/comic\\/[^\\/]+\\/(\\d+)', 1)
    local apiEndpoint = GetApiUrl() .. 'inventory_groups/comic_viewer_k?platform=web&store=web&alias=' .. contentSlug .. '&name=' .. episodeSlug .. '&preload=false&type=comic_episode'

    return Json.New(http.Get(apiEndpoint))

end

function GetSignedDataJson(episodeJson, quality)

    SetHttpHeaders()

    local contentId = episodeJson.SelectValue('data.extra.comic.id')
    local episodeId = episodeJson.SelectValue('data.extra.episode.id')

    local apiEndpoint = 'https://www.' .. module.Domain .. '/lz-api/v2/cloudfront/signed-url/generate?contentId=' .. contentId .. '&episodeId=' .. episodeId .. '&purchased=false&q=' .. quality .. '&firstCheckType=P'

    return Json.New(http.Get(apiEndpoint))

end

function SetHttpHeaders()

    local tokenScript = dom.SelectValue('(//script[contains(.,"__LZ_CONFIG__ ")])[last()]')
    local bearerToken = tokenScript:regex("\\btoken:\\s*'([^']+)", 1)

    http.Headers['accept'] = 'application/json, text/plain, */*'
    http.Headers['x-lz-adult'] = '1'
    http.Headers['x-lz-allowadult'] = 'true'
    http.Headers['x-lz-country'] = 'us'
    http.Headers['x-lz-locale'] = 'en-us'

    if(not isempty(bearerToken)) then
        http.Headers['authorization'] = 'Bearer ' .. bearerToken
    end

end
