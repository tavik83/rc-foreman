char = {"a","b","c","d","e","f","1","2","3","4","5","6","7","8","9","0"}
 
function generate(s)
 guid = { }
                for z = 1,s do
                a = math.random(1,#char) -- randomly choose a character from the "char" array
                x=char[a]
         table.insert(guid, x) -- add new index into array.
        end
        return(table.concat(guid)) -- concatenate all indicies of the "pass" array, then print out concatenation.
end