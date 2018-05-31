#pragma once
#include "Particle.h"

#include <list>

namespace Simple2D
{
	class ParticleEffect;

	class DLL_export ParticleEmitter
	{
	public:
		ParticleEmitter();
		~ParticleEmitter();

		void setDecription(const ParticleDescription& desc);
		void setParticleEffect(ParticleEffect* effect);

		void emitParticles(float dt);
		void addParticle();

		void update(float dt);

		void startEmitting();
		void stopEmitting();

		std::list<Particle*>* getParticleList() { return &vParticleList; }
		ParticleEffect* getParticleEffect() { return pParticleEffect; }

		//===================== 发射器属性 =====================

		/* 发射器位置 */
		MEMBER_FUNCTION(Vec2, EmitPos, emitPos);
		MEMBER_FUNCTION(Vec2, EmitPosVar, emitPosVar);

		/* 发射器发射粒子角度 */
		MEMBER_FUNCTION(float, EmitAngle, emitAngle);
		MEMBER_FUNCTION(float, EmitAngleVar, emitAngleVar);

		/* 发射器发射粒子给粒子的初速度大小 */
		MEMBER_FUNCTION(float, EmitSpeed, emitSpeed);
		MEMBER_FUNCTION(float, EmitSpeedVar, emitSpeedVar);

		/* 粒子数量 */
		MEMBER_FUNCTION(int, ParticleCount, particleCount);

		/* 发射速率  */
		MEMBER_FUNCTION(float, EmitRate, emitRate);

		/* 发射持续时间，-1 表示永远发射 */
		MEMBER_FUNCTION(float, Duration, duration);

	private:
		ParticleEffect* pParticleEffect;
		std::list<Particle*> vParticleList;

		bool bCanEmit;
		float fElapsed;
		float fEmitCounter;
	};
}