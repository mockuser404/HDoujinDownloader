function Register()

    module.Name = 'Anchira'
    module.Adult = true

    module.Domains.Add('anchira.to')

    module.Settings.AddCheck('Data saver', false)

end

local function GetApiUrl()
    return '/api/v1/'
end

local function GetApiJson(path)
   
    path = GetApiUrl() .. path

    http.Headers['Accept'] = '*/*'
    http.Headers['Referer'] = url
    http.Headers['X-Requested-With'] = 'XMLHttpRequest'

    local jsonStr = http.Get(path)

    if(not jsonStr:startswith('{')) then
        
        -- We're probably encountering a reader catcha.

        Fail(Error.CaptchaRequired.WithHelpLink("https://github.com/HDoujinDownloader/HDoujinDownloader/wiki/Downloading-from-Anchira"))

    end

    return Json.New(jsonStr)
    
end

local function GetGalleryPath()
    return url:regex('\\/g\\/(.+?\\/.+?)$', 1)
end

function GetInfo()

    local json = GetApiJson('library/' .. GetGalleryPath())

    info.Title = json.SelectValue('title')
    info.PageCount = json.SelectValue('pages')
    info.Tags = json.SelectValues('tags[*].name')
    info.Artist = json.SelectValues('tags[?(@.namespace==1)].name')

end

function GetPages()

    -- local appJsUrl = dom.SelectValue('//script[contains(@src,"/_app/")]/@src')
    -- local appJs = http.Get(appJsUrl)
    -- local dataUrl = appJs:regex('DATA_URL:\\s*\\"([^"]+)', 1)

    -- We get the image file names from the gallery metadata, and the path information from the library data.

    local dataUrl = '//kisakisexo.xyz'

    local galleryJson = GetApiJson('library/' .. GetGalleryPath())
    local libraryJson = GetApiJson('library/' .. GetGalleryPath() .. '/data')
    
    local id = libraryJson.SelectValue('id')
    local key = libraryJson.SelectValue('key')
    local hash = libraryJson.SelectValue('hash')
    local server = toboolean(module.Settings['Data saver']) and 'b' or 'a'

    for name in galleryJson.SelectValues('data[*].n') do
        
        local pageUrl = dataUrl .. '/' .. id .. '/' .. key .. '/' .. hash .. '/' .. server .. '/' .. EncodeUriComponent(name)

        pages.Add(pageUrl)

    end

end
