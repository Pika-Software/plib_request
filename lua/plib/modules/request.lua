plib.Require( 'chttp', true )
plib.Require( 'http' )

local ArgAssert = ArgAssert
local isnumber = isnumber
local string = string

-- HTTP/Enums
HTTP_GET = 0
HTTP_POST = 1
HTTP_HEAD = 2
HTTP_PUT = 3
HTTP_DELETE = 4
HTTP_PATCH = 5
HTTP_OPTIONS = 6

-- HTTP Request
local meta = {}
meta.__index = meta
debug.getregistry().HTTPRequest = meta

function meta:__tostring()
	return string.format( 'HTTP %s Request [%s]', self:GetMethod(), self:GetURL() )
end

function meta:Init()
	self.Method = self.Methods[ HTTP_GET ]
	self.Parameters = {}
	self.Callbacks = {}
	self.Headers = {}
end

-- Request Method
meta.Methods = {
	[HTTP_GET] = 'GET',
	[HTTP_POST] = 'POST',
	[HTTP_HEAD] = 'HEAD',
	[HTTP_PUT] = 'PUT',
	[HTTP_DELETE] = 'DELETE',
	[HTTP_PATCH] = 'PATCH',
	[HTTP_OPTIONS] = 'OPTIONS'
}

function meta:GetMethod()
	return self.Method
end

do
	local isstring = isstring
	function meta:SetMethod( any )
		local method = self.Methods[ isstring( any ) and string.lower( any ) or any ]
		if isstring( method ) then
			self.Method = method
		end
	end
end

-- URL
function meta:GetURL()
	return self.URL
end

function meta:SetURL( str )
	ArgAssert( str, 1, 'string' )
	self.URL = str
end

-- Timeout
do
	local cvars_Number = cvars.Number
	function meta:GetTimeout()
		if isnumber( self.Timeout ) then
			return self.Timeout
		end

		return cvars_Number( 'http_timeout', 60 )
	end
end

function meta:SetTimeout( int )
	ArgAssert( int, 1, 'number' )
	self.Timeout = int
end

-- Callbacks
function meta:GetCallbacks()
	return self.Callbacks
end

do
	local table_insert = table.insert
	function meta:AddCallback( func, onlySuccess, onlyFailure )
		ArgAssert( func, 1, 'function' )
		return table_insert(self.Callbacks, function( code, ... )
			if http.IsSuccess( code ) then
				if (onlyFailure) then
					return
				end
			else
				if (onlySuccess) then
					return
				end
			end

			func( code, ... )
		end)
	end
end

do
	local table_Empty = table.Empty
	function meta:ClearCallbacks()
		table_Empty( self.Callbacks )
	end
end

-- Parameters
function meta:GetParameters()
	return self.Parameters
end

function meta:SetParameters( tbl )
	ArgAssert( tbl, 1, 'table' )
	self.Parameters = tbl
end

function meta:SetParameter( key, value )
	ArgAssert( key, 1, 'string' )
	self.Parameters[ key ] = value
end

-- Headers
function meta:GetHeaders()
	return self.Headers
end

function meta:SetHeaders( tbl )
	ArgAssert( tbl, 1, 'table' )
	self.Headers = tbl
end

function meta:SetHeader( key, value )
	ArgAssert( key, 1, 'string' )
	self.Headers[ key ] = value
end

-- Body
function meta:GetBody()
	return self.Body
end

function meta:SetBody( str )
	ArgAssert( str, 1, 'string' )
	self.Body = str
end

-- Content Type
function meta:GetContentType()
	return self.ContentType
end

function meta:SetContentType( str )
	ArgAssert( str, 1, 'string' )
	self.ContentType = str
end

do

	local HTTP = CHTTP or reqwest or HTTP
	local plib_Debug = plib.Debug
	local ipairs = ipairs

	function meta:Run()
		local tbl = {
			['url'] = self:GetURL(),
			['method'] = self:GetMethod(),
			['parameters'] = self:GetParameters(),
			['headers'] = self:GetHeaders(),
			['body'] = self:GetBody(),
			['type'] = self:GetContentType(),
			['timeout'] = self:GetTimeout(),
			['success'] = function( ... )
				for num, func in ipairs( self:GetCallbacks() ) do
					func( ... )
				end
			end,
			['failed'] = function( ... )
				for num, func in ipairs( self:GetCallbacks() ) do
					func( 504, ... )
				end
			end
		}

		if HTTP( tbl ) then
			plib_Debug( '{1} request to {2} ', tbl.method, tbl.url )
		else
			plib_Debug( '{1} request failed! ({2})', tbl.method, tbl.url )
		end
	end

end

do
	local setmetatable = setmetatable
	function meta.new()
		local request = setmetatable( {}, meta )
		request:Init()
		return request
	end
end

function http.Request( url )
	ArgAssert( url, 1, 'string' )
	local request = meta.new()
	request:SetURL( url )
	return request
end