local debounce = false


function onHit(hit)
	local human = hit.Parent:findFirstChild("Humanoid")
	if (human ~= nil) and debounce == false then

                debounce = true

local message = Instance.new("Message")
message.Parent = game.Players:playerFromCharacter(hit.Parent)
message.Text = "Hm hm, hm, hmm!~" --put your messege in the "" if you need more messege spots copy the message.Text= "" and wait lines
wait(1) --time before next words
message.Text = " " --put your messege in the "" if you need more messege spots copy the message.Text= "" and wait lines
wait(0.2) --time before next words
message.Text = "Hm hm, hm, hmm!~" --put your messege in the "" if you need more messege spots copy the message.Text= "" and wait lines
wait(1) --time before next words
message.Text = " " --put your messege in the "" if you need more messege spots copy the message.Text= "" and wait lines
wait(0.2) --time before next words
message.Text = "Hm~ hm~ hm~ hmm!~" --put your messege in the "" if you need more messege spots copy the message.Text= "" and wait lines
wait(1) --time before next words
message.Text = "Hm hm, hm, hmm!~" --put your messege in the "" if you need more messege spots copy the message.Text= "" and wait lines
wait(2) --time before next words

message:Remove ()

                debounce = false
	end
end

script.Parent.Touched:connect(onHit)
