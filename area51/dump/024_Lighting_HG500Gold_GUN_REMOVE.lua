sp=script.Parent
mesh=sp:findFirstChild("Mesh")
rf=0
if mesh~=nil then
for i=1, 5 do
mesh.Scale=mesh.Scale+Vector3.new(.1, .1, 0)
rf=rf+.1
sp.Reflectance=rf
wait(.00001)
end
tr=0
wait()
for i=1, 5 do
mesh.Scale=mesh.Scale-Vector3.new(.1, .1, 0)
rf=rf-.1
tr=tr-.1
sp.Reflectance=rf
sp.Transparency=tr
wait(.00001)
end
sp:remove()
script:remove()
end
