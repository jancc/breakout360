Audio = {}
Audio.streamSource = nil
Audio.mute = false
Audio.sfxSources = {}
Audio.loadSound = function(self, filename)
    local sfxSource = love.audio.newSource("sfx/" .. filename, "static")
    sfxSource:setLooping(false)
    self.sfxSources[filename] = sfxSource
end
Audio.loadAll = function(self)
    self:loadSound("border.wav")
    self:loadSound("paddle.wav")
    self:loadSound("brick.wav")
end
Audio.playSound = function(self, id)
	if self.mute then
		return
	end
    self.sfxSources[id]:play()
end
Audio.playMusic = function(self, filename)
    self.streamSource = love.audio.newSource("music/" .. filename)
    self.streamSource:setLooping(true)
    self.streamSource:setPitch(0.9)
    self.streamSource:play()
end
