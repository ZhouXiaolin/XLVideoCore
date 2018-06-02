#include "ParticleEmitter.h"
#include "ParticleEffect.h"
#include "ParticleMemory.h"

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

namespace XLSimple2D
{
	ParticleEmitter::ParticleEmitter()
		: pParticleEffect(nullptr)
		, bCanEmit(true)
		, fElapsed(0)
		, fEmitCounter(0)
	{
	}

	ParticleEmitter::~ParticleEmitter()
	{
		if ( pParticleEffect ) {
			delete pParticleEffect;
		}
	}

	void ParticleEmitter::setDecription(const ParticleDescription& desc)
	{
		/* ���������� */
		emitPos = desc.vEmitPos;
		emitPosVar = desc.vEmitPosVar;

		emitAngle = desc.fEmitAngle;
		emitAngleVar = desc.fEmitAngleVar;

		emitSpeed = desc.fEmitSpeed;
		emitSpeedVar = desc.fEmitSpeedVar;

		emitRate = desc.fEmitRate;
		duration = desc.fDuration;
		particleCount = desc.nParticleCount;

		/* �������� effect */
		ParticleEffect* effect = nullptr;
		if ( desc.emitterType == EmitterType::EMITTER_TYPE_GRAVITY ) {
			effect = new GravityParticleEffect();
		}
		else {
			effect = new RadialParticleEffect();
		}

		effect->setDecription(desc);
		this->setParticleEffect(effect);
	}

	void ParticleEmitter::setParticleEffect(ParticleEffect* effect)
	{
		if ( pParticleEffect ) {
			delete pParticleEffect;
		}
		pParticleEffect = effect;
	}

	void ParticleEmitter::update(float dt)
	{
		if ( bCanEmit == false ) return;

		this->emitParticles(dt);
		pParticleEffect->update(this, dt);
	}

	void ParticleEmitter::emitParticles(float dt)
	{
		/* ����һ����������ʱ�� */
		float emit_particle_time = 1 / emitRate;

		/* �ۼƷ���ʱ�� */
		if ( vParticleList.size() < particleCount ) {
			fEmitCounter += dt;
		}

		/* ��ʱ�� emit_counter ���� emit_counter / rate ������ */
		while ( vParticleList.size() < particleCount && fEmitCounter > 0 ) {
			this->addParticle();
			fEmitCounter -= emit_particle_time;
		}

		fElapsed += dt;
		if ( duration != -1 && duration < fElapsed ) {
			fElapsed = 0;
			this->stopEmitting();
		}
	}

	void ParticleEmitter::addParticle()
	{
		if ( vParticleList.size() == particleCount ) return;

		Particle* particle = ParticleMemory::allocParticle();
		if ( particle == nullptr ) return;

		/* �洢���Ӳ���ʼ������ */
		vParticleList.push_back(particle);
		pParticleEffect->initParticle(this, particle);
	}

	void ParticleEmitter::startEmitting()
	{
		bCanEmit = true;
	}

	void ParticleEmitter::stopEmitting()
	{
		bCanEmit = false;

		/* �ͷ�����δ��������� */
		for ( auto& ele : vParticleList ) {
			ParticleMemory::freeParticle(ele);
		}
		vParticleList.clear();
	}
}
