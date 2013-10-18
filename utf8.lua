-- ABNF from RFC 3629
--
-- UTF8-octets = *( UTF8-char )
-- UTF8-char = UTF8-1 / UTF8-2 / UTF8-3 / UTF8-4
-- UTF8-1 = %x00-7F
-- UTF8-2 = %xC2-DF UTF8-tail
-- UTF8-3 = %xE0 %xA0-BF UTF8-tail / %xE1-EC 2( UTF8-tail ) /
-- %xED %x80-9F UTF8-tail / %xEE-EF 2( UTF8-tail )
-- UTF8-4 = %xF0 %x90-BF 2( UTF8-tail ) / %xF1-F3 3( UTF8-tail ) /
-- %xF4 %x80-8F 2( UTF8-tail )
-- UTF8-tail = %x80-BF

-- 0xxxxxxx                            | 007F   (127)
-- 110xxxxx	10xxxxxx                   | 07FF   (2047)
-- 1110xxxx	10xxxxxx 10xxxxxx          | FFFF   (65535)
-- 11110xxx	10xxxxxx 10xxxxxx 10xxxxxx | 10FFFF (1114111)

local maxitems = 256
local utf8char = '[%z\1-\127\194-\244][\128-\191]*'

local utf8 = {}

-- returns the utf8 character byte length at first-byte i
utf8.clen =
function (s, i)
   local c = string.match(s, utf8char, i)

   if not c then
      return
   end

   return #c
end

-- maps f over s's utf8 characters f can accept args: (visual_index, utf8_character, byte_index)
utf8.map =
function (s, f)
   local i = 0

   for b, c in string.gmatch(s, '()(' .. utf8char .. ')') do
      i = i + 1
      f(i, c, b)
   end 
end

-- generator to iterate over all utf8 chars
utf8.iter =
function (s)
   return coroutine.wrap(function () return utf8.map(s, coroutine.yield) end)
end

-- return the utf8 character at the "visual index" 'i' + actual byte index
utf8.at =
function (s, x)
   for i, c, b in utf8.iter(s) do
      if i == x then
         return c, b
      end
   end
end

-- returns the number of characters in a UTF-8 string
utf8.len =
function (s)
   -- count the number of non-continuing bytes
   return select(2, string.gsub(s, '[^\128-\193]', ''))
end

-- like string.sub() but i, j are utf8 strings
utf8.sub =
function (s, i, j)
   i = string.find(s, i, 1, true)

   if not i then
      return ''
   end

   if j then
      local tmp = string.find(s, j, 1, true)

      if not tmp then
         return ''
      end

      j = (tmp - 1) + #j
   end

   return string.sub(s, i, j)
end

-- basic replacement map:
utf8._map = {
   -- German
   ['Ä'] = 'Ae', ['Ö'] = 'Oe', ['Ü'] = 'Ue', ['ä'] = 'ae', ['ö'] = 'oe', ['ü'] = 'ue', ['ß'] = 'ss',
   ['ẞ'] = 'SS',
   -- Latin
   ['À'] = 'A', ['Á'] = 'A', ['Â'] = 'A', ['Ã'] = 'A', ['Ä'] = 'A', ['Å'] = 'A',['Ă'] = 'A', ['Æ'] = 'AE', ['Ç'] =
   'C', ['È'] = 'E', ['É'] = 'E', ['Ê'] = 'E', ['Ë'] = 'E', ['Ì'] = 'I', ['Í'] = 'I', ['Î'] = 'I',
   ['Ï'] = 'I', ['Ð'] = 'D', ['Ñ'] = 'N', ['Ò'] = 'O', ['Ó'] = 'O', ['Ô'] = 'O', ['Õ'] = 'O', ['Ö'] =
   'O', ['Ő'] = 'O', ['Ø'] = 'O',['Ș'] = 'S',['Ț'] = 'T', ['Ù'] = 'U', ['Ú'] = 'U', ['Û'] = 'U', ['Ü'] = 'U', ['Ű'] = 'U',
   ['Ý'] = 'Y', ['Þ'] = 'TH', ['ß'] = 'ss', ['à'] = 'a', ['á'] = 'a', ['â'] = 'a', ['ã'] = 'a', ['ä'] =
   'a', ['å'] = 'a', ['ă'] = 'a', ['æ'] = 'ae', ['ç'] = 'c', ['è'] = 'e', ['é'] = 'e', ['ê'] = 'e', ['ë'] = 'e',
   ['ì'] = 'i', ['í'] = 'i', ['î'] = 'i', ['ï'] = 'i', ['ð'] = 'd', ['ñ'] = 'n', ['ò'] = 'o', ['ó'] =
   'o', ['ô'] = 'o', ['õ'] = 'o', ['ö'] = 'o', ['ő'] = 'o', ['ø'] = 'o', ['ș'] = 's', ['ț'] = 't', ['ù'] = 'u', ['ú'] = 'u',
   ['û'] = 'u', ['ü'] = 'u', ['ű'] = 'u', ['ý'] = 'y', ['þ'] = 'th', ['ÿ'] = 'y',
   ['©'] = '(c)',
   -- Greek
   ['α'] = 'a', ['β'] = 'b', ['γ'] = 'g', ['δ'] = 'd', ['ε'] = 'e', ['ζ'] = 'z', ['η'] = 'h', ['θ'] = '8',
   ['ι'] = 'i', ['κ'] = 'k', ['λ'] = 'l', ['μ'] = 'm', ['ν'] = 'n', ['ξ'] = '3', ['ο'] = 'o', ['π'] = 'p',
   ['ρ'] = 'r', ['σ'] = 's', ['τ'] = 't', ['υ'] = 'y', ['φ'] = 'f', ['χ'] = 'x', ['ψ'] = 'ps', ['ω'] = 'w',
   ['ά'] = 'a', ['έ'] = 'e', ['ί'] = 'i', ['ό'] = 'o', ['ύ'] = 'y', ['ή'] = 'h', ['ώ'] = 'w', ['ς'] = 's',
   ['ϊ'] = 'i', ['ΰ'] = 'y', ['ϋ'] = 'y', ['ΐ'] = 'i',
   ['Α'] = 'A', ['Β'] = 'B', ['Γ'] = 'G', ['Δ'] = 'D', ['Ε'] = 'E', ['Ζ'] = 'Z', ['Η'] = 'H', ['Θ'] = '8',
   ['Ι'] = 'I', ['Κ'] = 'K', ['Λ'] = 'L', ['Μ'] = 'M', ['Ν'] = 'N', ['Ξ'] = '3', ['Ο'] = 'O', ['Π'] = 'P',
   ['Ρ'] = 'R', ['Σ'] = 'S', ['Τ'] = 'T', ['Υ'] = 'Y', ['Φ'] = 'F', ['Χ'] = 'X', ['Ψ'] = 'PS', ['Ω'] = 'W',
   ['Ά'] = 'A', ['Έ'] = 'E', ['Ί'] = 'I', ['Ό'] = 'O', ['Ύ'] = 'Y', ['Ή'] = 'H', ['Ώ'] = 'W', ['Ϊ'] = 'I',
   ['Ϋ'] = 'Y',
   -- Turkish
   ['ş'] = 's', ['Ş'] = 'S', ['ı'] = 'i', ['İ'] = 'I', ['ç'] = 'c', ['Ç'] = 'C', ['ü'] = 'u', ['Ü'] = 'U',
   ['ö'] = 'o', ['Ö'] = 'O', ['ğ'] = 'g', ['Ğ'] = 'G',
   -- Russian
   ['а'] = 'a', ['б'] = 'b', ['в'] = 'v', ['г'] = 'g', ['д'] = 'd', ['е'] = 'e', ['ё'] = 'yo', ['ж'] = 'zh',
   ['з'] = 'z', ['и'] = 'i', ['й'] = 'j', ['к'] = 'k', ['л'] = 'l', ['м'] = 'm', ['н'] = 'n', ['о'] = 'o',
   ['п'] = 'p', ['р'] = 'r', ['с'] = 's', ['т'] = 't', ['у'] = 'u', ['ф'] = 'f', ['х'] = 'h', ['ц'] = 'c',
   ['ч'] = 'ch', ['ш'] = 'sh', ['щ'] = 'sh', ['ъ'] = '', ['ы'] = 'y', ['ь'] = '', ['э'] = 'e', ['ю'] = 'yu',
   ['я'] = 'ya',
   ['А'] = 'A', ['Б'] = 'B', ['В'] = 'V', ['Г'] = 'G', ['Д'] = 'D', ['Е'] = 'E', ['Ё'] = 'Yo', ['Ж'] = 'Zh',
   ['З'] = 'Z', ['И'] = 'I', ['Й'] = 'J', ['К'] = 'K', ['Л'] = 'L', ['М'] = 'M', ['Н'] = 'N', ['О'] = 'O',
   ['П'] = 'P', ['Р'] = 'R', ['С'] = 'S', ['Т'] = 'T', ['У'] = 'U', ['Ф'] = 'F', ['Х'] = 'H', ['Ц'] = 'C',
   ['Ч'] = 'Ch', ['Ш'] = 'Sh', ['Щ'] = 'Sh', ['Ъ'] = '', ['Ы'] = 'Y', ['Ь'] = '', ['Э'] = 'E', ['Ю'] = 'Yu',
   ['Я'] = 'Ya',
   ['№'] = '',
   -- Ukrainian
   ['Є'] = 'Ye', ['І'] = 'I', ['Ї'] = 'Yi', ['Ґ'] = 'G', ['є'] = 'ye', ['і'] = 'i', ['ї'] = 'yi', ['ґ'] = 'g',
   -- Czech
   ['č'] = 'c', ['ď'] = 'd', ['ě'] = 'e', ['ň'] = 'n', ['ř'] = 'r', ['š'] = 's', ['ť'] = 't', ['ů'] = 'u',
   ['ž'] = 'z', ['Č'] = 'C', ['Ď'] = 'D', ['Ě'] = 'E', ['Ň'] = 'N', ['Ř'] = 'R', ['Š'] = 'S', ['Ť'] = 'T',
   ['Ů'] = 'U', ['Ž'] = 'Z',
   -- Polish
   ['ą'] = 'a', ['ć'] = 'c', ['ę'] = 'e', ['ł'] = 'l', ['ń'] = 'n', ['ó'] = 'o', ['ś'] = 's', ['ź'] = 'z',
   ['ż'] = 'z', ['Ą'] = 'A', ['Ć'] = 'C', ['Ę'] = 'e', ['Ł'] = 'L', ['Ń'] = 'N', ['Ó'] = 'O', ['Ś'] = 'S',
   ['Ź'] = 'Z', ['Ż'] = 'Z',
   -- Romanian
   ['ă'] = 'a', ['â'] = 'a', ['î'] = 'i', ['ș'] = 's', ['ț'] = 't',
   -- Latvian
   ['ā'] = 'a', ['č'] = 'c', ['ē'] = 'e', ['ģ'] = 'g', ['ī'] = 'i', ['ķ'] = 'k', ['ļ'] = 'l', ['ņ'] = 'n',
   ['š'] = 's', ['ū'] = 'u', ['ž'] = 'z', ['Ā'] = 'A', ['Č'] = 'C', ['Ē'] = 'E', ['Ģ'] = 'G', ['Ī'] = 'i',
   ['Ķ'] = 'k', ['Ļ'] = 'L', ['Ņ'] = 'N', ['Š'] = 'S', ['Ū'] = 'u', ['Ž'] = 'Z',
   -- Lithuanian
   ['ą'] = 'a', ['č'] = 'c', ['ę'] = 'e', ['ė'] = 'e', ['į'] = 'i', ['š'] = 's', ['ų'] = 'u', ['ū'] = 'u', ['ž'] = 'z',
   ['Ą'] = 'A', ['Č'] = 'C', ['Ę'] = 'E', ['Ė'] = 'E', ['Į'] = 'I', ['Š'] = 'S', ['Ų'] = 'U', ['Ū'] = 'U', ['Ž'] = 'Z',
}

-- replace all utf8 chars with mapping
utf8.replace =
function (s, map)
   map = map or utf8._map
   local new = {}

   for _, c in utf8.iter(s) do
      table.insert(new, map[c] or c)

      if #new > maxitems then
         new = { table.concat(new) }
      end
   end

   return table.concat(new)
end

-- reverse a utf8 string
utf8.reverse =
function (s)
   local new = {}

   for _, c in utf8.iter(s) do
      table.insert(new, 1, c)

      if #new > maxitems then
         new = { table.concat(new) }
      end
   end

   return table.concat(new)
end

-- strip utf8 characters from a string
utf8.strip =
function (s)
   local new = {}

   for _, c in utf8.iter(s) do
      if #c == 1 then
         table.insert(new, c)

         if #new > maxitems then
            new = { table.concat(new) }
         end
      end
   end

   return table.concat(new)
end

return utf8
