#include "ParticleEffect.h"
#include "ParticleEmitter.h"
#include "ParticleSystem.h"
#include "ParticleMemory.h"

#include "Random.h"

namespace Simple2D
{
	ParticleEffect::ParticleEffect()
	{
		motionMode = MotionMode::MOTION_MODE_FREE;
	}

	void ParticleEffect::setDecription(const ParticleDescription& desc)
	{
		life = desc.fLife;
		lifeVar = desc.fLifeVar;

		beginColor = desc.cBeginColor;
		beginColorVar = desc.cBeginColorVar;
		endColor = desc.cEndColor;
		endColorVar = desc.cEndColorVar;

		beginSize = desc.fBeginSize;
		beginSizeVar = desc.fBeginSizeVar;
		endSize = desc.fEndSize;
		endSizeVar = desc.fEndSizeVar;

		beginSpin = desc.fBeginSpin;
		beginSpinVar = desc.fBeginSpinVar;
		endSpin = desc.fEndSpin;
		endSpinVar = desc.fEndSpinVar;

		motionMode = desc.motionMode;

		gravityMode = desc.gravityMode;
		radiusMode = desc.radiusMode;
	}

	void ParticleEffect::initParticle(ParticleEmitter* pe, Particle* particle)
	{
		/* 粒子起始位置 */
		particle->vPos.x = pe->getEmitPos().x + pe->getEmitPosVar().x * RANDOM_MINUS1_1();
		particle->vPos.y = pe->getEmitPos().y + pe->getEmitPosVar().y * RANDOM_MINUS1_1();

		particle->vStartPos = pe->getEmitPos();
		particle->vChangePos = particle->vPos;

		/* 粒子生命 */
		particle->fRemainingLife = MAX(0.1, life + lifeVar * RANDOM_MINUS1_1());

		/* 粒子的颜色变化值 */
		Color begin_color, end_color;
		begin_color.r = CLAMPF(beginColor.r + beginColorVar.r * RANDOM_MINUS1_1(), 0, 1);
		begin_color.g = CLAMPF(beginColor.g + beginColorVar.g * RANDOM_MINUS1_1(), 0, 1);
		begin_color.b = CLAMPF(beginColor.b + beginColorVar.b * RANDOM_MINUS1_1(), 0, 1);
		begin_color.a = CLAMPF(beginColor.a + beginColorVar.a * RANDOM_MINUS1_1(), 0, 1);

		end_color.r = CLAMPF(endColor.r + endColorVar.r * RANDOM_MINUS1_1(), 0, 1);
		end_color.g = CLAMPF(endColor.g + endColorVar.g * RANDOM_MINUS1_1(), 0, 1);
		end_color.b = CLAMPF(endColor.b + endColorVar.b * RANDOM_MINUS1_1(), 0, 1);
		end_color.a = CLAMPF(endColor.a + endColorVar.a * RANDOM_MINUS1_1(), 0, 1);

		float tmp = 1 / (particle->fRemainingLife);
		particle->cColor = begin_color;
		particle->cDeltaColor.r = (end_color.r - begin_color.r) * tmp;
		particle->cDeltaColor.g = (end_color.g - begin_color.g) * tmp;
		particle->cDeltaColor.b = (end_color.b - begin_color.b) * tmp;
		particle->cDeltaColor.a = (end_color.a - begin_color.a) * tmp;

		/* 粒子大小 */
		float begin_size = MAX(0, beginSize + beginSizeVar * RANDOM_MINUS1_1());
		float end_size = MAX(0, endSize + endSizeVar * RANDOM_MINUS1_1());

		particle->fSize = begin_size;
		particle->fDeltaSize = (end_size - begin_size) / particle->fRemainingLife;

		/* 粒子旋转角度 */
		float begin_spin = toRadian(MAX(0, beginSpin + beginSpinVar * RANDOM_MINUS1_1()));
		float end_spin = toRadian(MAX(0, endSpin + endSpinVar * RANDOM_MINUS1_1()));

		particle->fRotation = begin_spin;
		particle->fDeltaRotation = (end_spin - begin_spin) / particle->fRemainingLife;
	}

	//---------------------------------------------------------------------
	// GravityParticleEffect
	//---------------------------------------------------------------------
	void GravityParticleEffect::initParticle(ParticleEmitter* pe, Particle* particle)
	{
		ParticleEffect::initParticle(pe, particle);

		/* 计算粒子受到发射器给的初速度大小 */
		float particleSpeed = pe->getEmitSpeed() + pe->getEmitSpeedVar() * RANDOM_MINUS1_1();

		/* 计算粒子初速度的方向，即发射器发射粒子的发射方向 */
		float angle = pe->getEmitAngle() + pe->getEmitAngleVar() * RANDOM_MINUS1_1();
		Vec2 particleDirection = Vec2(cosf(toRadian(angle)), sinf(toRadian(angle)));
		
		/* 设置粒子的起始加速度（包括大小及方向）*/
		particle->gravityMode.vInitialVelocity = particleDirection * particleSpeed;

		/* 粒子切向加速度、径向加速度 */
		particle->gravityMode.fTangentialAccel = gravityMode.fTangentialAccel + gravityMode.fTangentialAccelVar * RANDOM_MINUS1_1();
		particle->gravityMode.fRadialAccel = gravityMode.fRadialAccel + gravityMode.fRadialAccelVar * RANDOM_MINUS1_1();
	}

	void GravityParticleEffect::update(ParticleEmitter* pe, float dt)
	{
		std::list<Particle*>* indexList = pe->getParticleList();

		for ( auto it = indexList->begin(); it != indexList->end(); ) {
			Particle* p = (*it);

			p->fRemainingLife -= dt;

			if ( p->fRemainingLife > 0 ) {
				static Vec2 offset, radial, tangential;

				/* 径向加速度 */
				if ( p->vChangePos.x || p->vChangePos.y ) {
					offset = p->gravityMode.vInitialVelocity;
					radial = offset.normalize();
				}
				tangential = radial;
				radial = radial * p->gravityMode.fRadialAccel;

				/* 切向加速度 */
				float newy = tangential.x;
				tangential.x = -tangential.y;
				tangential.y = newy;
				tangential = tangential * p->gravityMode.fTangentialAccel;

				/* 合力 */
				offset = (radial + tangential + gravityMode.vGravity) * dt;

				/* 在合力作用下移动粒子 */
				p->gravityMode.vInitialVelocity = p->gravityMode.vInitialVelocity + offset;
				p->vChangePos = p->vChangePos + p->gravityMode.vInitialVelocity * dt;

				/* 属性变化 */
				p->cColor = p->cColor + p->cDeltaColor * dt;
				p->fSize = MAX(0, p->fSize + p->fDeltaSize * dt);
				p->fRotation = p->fRotation + p->fDeltaRotation * dt;

				if ( motionMode == MotionMode::MOTION_MODE_RELATIVE ) {
					Vec2 diff = pe->getEmitPos() - p->vStartPos;
					p->vPos = p->vChangePos + diff;
				}
				else {
					p->vPos = p->vChangePos;
				}
				++it;
			}
			else {
				/* 移除结束生命周期的粒子 */
				ParticleMemory::freeParticle(*it);
				it = indexList->erase(it);
			}
		}
	}

	//---------------------------------------------------------------------
	// GravityParticleEffect
	//---------------------------------------------------------------------
	void RadialParticleEffect::initParticle(ParticleEmitter* pe, Particle* particle)
	{
		ParticleEffect::initParticle(pe, particle);

		float begin_radius = radiusMode.fBeginRadius + radiusMode.fBeginRadiusVar * RANDOM_MINUS1_1();
		float end_radius = radiusMode.fEndRadius + radiusMode.fEndRadiusVar * RANDOM_MINUS1_1();
		
		particle->radiusMode.fRadius = begin_radius;
		particle->radiusMode.fDelatRadius = (end_radius - begin_radius) / particle->fRemainingLife;

		float degress = pe->getEmitAngle() + pe->getEmitAngleVar() * RANDOM_MINUS1_1();
		particle->radiusMode.fAngle = toRadian(degress);

		degress = radiusMode.fSpinPerSecond + radiusMode.fSpinPerSecondVar * RANDOM_MINUS1_1();
		particle->radiusMode.fDegressPerSecond = toRadian(degress);
	}

	void RadialParticleEffect::update(ParticleEmitter* pe, float dt)
	{
		std::list<Particle*>* indexList = pe->getParticleList();

		for ( auto it = indexList->begin(); it != indexList->end(); ) {
			Particle* p = (*it);

			p->fRemainingLife -= dt;

			if ( p->fRemainingLife > 0 ) {
				p->radiusMode.fAngle += p->radiusMode.fDegressPerSecond * dt;
				p->radiusMode.fRadius += p->radiusMode.fDelatRadius * dt;

				p->vChangePos.x = cosf(p->radiusMode.fAngle) * p->radiusMode.fRadius;
				p->vChangePos.y = sinf(p->radiusMode.fAngle) * p->radiusMode.fRadius;
				
				if ( motionMode == MotionMode::MOTION_MODE_FREE ) {
					p->vPos = p->vChangePos + pe->getEmitPos();
				}
				else {
					p->vPos = p->vChangePos + p->vStartPos;
				}

				/* 属性变化 */
				p->cColor = p->cColor + p->cDeltaColor * dt;
				p->fSize = MAX(0, p->fSize + p->fDeltaSize * dt);
				p->fRotation = p->fRotation + p->fDeltaRotation * dt;
				++it;
			}
			else {
				/* 移除结束生命周期的粒子 */
				ParticleMemory::freeParticle(*it);
				it = indexList->erase(it);
			}
		}
	}
}
