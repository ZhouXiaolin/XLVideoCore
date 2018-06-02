#pragma once

#include "Particle.h"
#include "ParticleEmitter.h"
#include "ParticleEffect.h"
#include "ParticleDescription.h"

#include "TextureManager.hpp"
#include "Renderer.h"

#include <map>
#include <vector>

namespace XLSimple2D
{
	class DLL_export ParticleSystem
	{
		typedef std::map<std::string, std::string> ParticleConfigMap;

	public:
		ParticleSystem();
		~ParticleSystem();

		void initWithPlist(const char* filename);
		void setDescription(const ParticleDescription& desc);

		void setTexture(const char* filename);

		void update(float dt);
        RenderUnit render();

		ParticleEffect* getEffect() { return pEmitter->getParticleEffect(); }
		ParticleEmitter* getEmitter() { return pEmitter; }

	private:
		/* ������������ϵͳ�������ļ� */
		static ParticleConfigMap parseParticlePlistFile(const char* filename);

		/* ������������ */
		static ParticleDescription createParticleDescription(ParticleConfigMap& map);

	private:
		ParticleEmitter* pEmitter;
        Texture* texture;

		std::vector<Vec3> vPositions;
		std::vector<Color> vColors;
		int nPositionIndex;
	};


	//-------------------------------------------------------------------------------
	// ����ϵͳ������
	// ParticleSystemManager
	//-------------------------------------------------------------------------------
	class DLL_export ParticleSystemManager
	{
	public:
		ParticleSystemManager();
		~ParticleSystemManager();

		void update(float dt);
		void render(std::vector<RenderUnit>& units);

		void appendParticleSystem(ParticleSystem* ps) { vParticleSystems.push_back(ps); }

	private:
		std::vector<ParticleSystem*> vParticleSystems;
	};
}
