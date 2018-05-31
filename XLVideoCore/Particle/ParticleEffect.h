#pragma once
#include "Particle.h"

namespace Simple2D
{
	class ParticleEmitter;
	class ParticleSystem;

	class DLL_export ParticleEffect
	{
	public:
		ParticleEffect();
		virtual ~ParticleEffect() {}

		void setDecription(const ParticleDescription& desc);

		/* ��ʼ������ */
		virtual void initParticle(ParticleEmitter* pe, Particle* particle);

		/* �������� */
		virtual void update(ParticleEmitter* pe, float dt) = 0;

		void setMotionMode(MotionMode mode) { motionMode = mode; }

	public:
		/* ������������ */
		VIR_MEMBER_FUNCTION(float, Life, life);
		VIR_MEMBER_FUNCTION(float, LifeVar, lifeVar);

		/* ������ʼ��ɫ  */
		VIR_MEMBER_FUNCTION(Color, BeginColor, beginColor);
		VIR_MEMBER_FUNCTION(Color, BeginColorVar, beginColorVar);

		/* ���ӽ�����ɫ */
		VIR_MEMBER_FUNCTION(Color, EndColor, endColor);
		VIR_MEMBER_FUNCTION(Color, EndColorVar, endColorVar);

		/* ������ʼ��С */
		VIR_MEMBER_FUNCTION(float, BeginSize, beginSize);
		VIR_MEMBER_FUNCTION(float, BeginSizeVar, beginSizeVar);

		/* ���ӽ�����С */
		VIR_MEMBER_FUNCTION(float, EndSize, endSize);
		VIR_MEMBER_FUNCTION(float, EndSizeVar, endSizeVar);

		/* ������ʼ��ת�Ƕ� */
		VIR_MEMBER_FUNCTION(float, BeginSpin, beginSpin);
		VIR_MEMBER_FUNCTION(float, BeginSpinVar, beginSpinVar);

		/* ���ӽ�����ת�Ƕ� */
		VIR_MEMBER_FUNCTION(float, EndSpin, endSpin);
		VIR_MEMBER_FUNCTION(float, EndSpinVar, endSpinVar);

	public:
		MotionMode motionMode;

		GravityMode gravityMode;
		RadiusMode radiusMode;
	};

	//---------------------------------------------------------------------
	// GravityParticleEffect
	//---------------------------------------------------------------------
	class DLL_export GravityParticleEffect : public ParticleEffect
	{
	public:
		void initParticle(ParticleEmitter* pe, Particle* particle) override;
		void update(ParticleEmitter* pe, float dt) override;
	};

	//---------------------------------------------------------------------
	// RadialParticleEffect
	//---------------------------------------------------------------------
	class DLL_export RadialParticleEffect : public ParticleEffect
	{
	public:
		void initParticle(ParticleEmitter* pe, Particle* particle) override;
		void update(ParticleEmitter* pe, float dt) override;
	};
}