function ChangeFace(hit)
if hit.Parent:FindFirstChild("Humanoid") ~= nil then 
hit.Parent.Head.face.Texture = script.Parent.Decal.Texture
hit.Parent.Head.Mesh.Scale = Vector3.new(0.5, 1, 1)
hit.Parent.Head.Mesh.MeshType = "Brick"
end 
end 
script.Parent.Touched:connect(ChangeFace)