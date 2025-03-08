class BouncingGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;
var vector oldVelocity;
var bool isSpacePressed;
var SoundCue bounceSound;
var PhysicalMaterial bouncingMaterial;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		bouncingMaterial.ImpactEffect=none;
		bouncingMaterial.ImpactSound=bounceSound;

		gMe.mRagdollLandSpeed=100000;
		MakeItBounce(gMe);
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_Jump", string( newKey ) ) )
		{
			isSpacePressed=true;
		}

		if( localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ) )
		{
			gMe.SetTimer( 2.0f, false, NameOf( MakeGrabbedItemBounce ), self );
		}
	}
	else if( keyState == KS_Up )
	{
		if( localInput.IsKeyIsPressed( "GBA_Jump", string( newKey ) ) )
		{
			isSpacePressed=false;
		}

		if( localInput.IsKeyIsPressed( "GBA_AbilityBite", string( newKey ) ) )
		{
			if(gMe.IsTimerActive(NameOf( MakeGrabbedItemBounce ), self))
			{
				gMe.ClearTimer(NameOf( MakeGrabbedItemBounce ), self);
			}
		}
	}
}

function MakeGrabbedItemBounce()
{
	MakeItBounce(gMe);
	if(MakeItBounce(gMe.mGrabbedItem))
	{
		gMe.PlaySound( bounceSound );
	}
}

function bool MakeItBounce(Actor act)
{
	local string oldName;
	local GGPawn gpawn;
	local GGScoreActorInterface scoreAct;
	local PhysicalMaterial physMat;

	if(act == none)
		return false;

	scoreAct=GGScoreActorInterface(act);
	gpawn=GGPawn(act);

	oldName=scoreAct!=none?scoreAct.GetActorName():"";
	if(oldName == "")
	{
		physMat=bouncingMaterial;
	}
	else
	{
		if(InStr(oldName, "Bouncing") == INDEX_NONE)
		{
			oldName = "Bouncing" @ oldName;
		}

		physMat=new class'PhysicalMaterial' (bouncingMaterial);
		//physMat.PhysicalMaterialProperty=new class'GGPhysicalMaterialProperty' (GGPhysicalMaterialProperty(bouncingMaterial.PhysicalMaterialProperty));
		GGPhysicalMaterialProperty(physMat.PhysicalMaterialProperty).SetActorName(oldName);
	}
	act.bBounce = true;
	if(gpawn != none)
	{
		gpawn.mesh.SetPhysMaterialOverride(physMat);
	}
	else
	{
		act.CollisionComponent.SetPhysMaterialOverride(physMat);
	}

	return true;
}

function TickMutatorComponent(float DeltaTime)
{
	super.TickMutatorComponent(DeltaTime);

	if(gMe.Physics == PHYS_Falling)
	{
		oldVelocity=gMe.Velocity;
	}
	if(gMe.Physics == PHYS_Walking || gMe.Physics == PHYS_Spider)
	{
		if(isSpacePressed)
		{
			oldVelocity=vect(0,0,0);
		}
		if(oldVelocity.z < -FMax(gMe.JumpZ * 1.1f, 1000.f))
		{
			bounce();
		}
	}
	if(gMe.Physics == PHYS_RigidBody)
	{
		oldVelocity=vect(0,0,0);
	}

	//WorldInfo.Game.Broadcast(self, "Physics : "$gMe.Physics);
	//WorldInfo.Game.Broadcast(self, "oldV : "$oldVelocity);
}

function bounce()
{
	local vector u, w, n;
	local Actor actorBouncedOn;

	n=gMe.Floor;
	actorBouncedOn=getBouncedActor();
	gMe.OnBounce(n, actorBouncedOn);

	gMe.PlaySound( bounceSound );

	u = ((oldVelocity dot n) / (n dot n)) * n;
	w = oldVelocity - u;
	gMe.SetPhysics(PHYS_Falling);
	gMe.Velocity = (w - u) * 1.1f;

	gMe.PostBounce(n, actorBouncedOn);
}

function Actor getBouncedActor()
{
	local vector loc, norm, end;
	local Actor bouncedActor;

	end=gMe.Location;
	end.z*= -1000;
	bouncedActor = myMut.Trace (loc, norm, end, gMe.Location);
	return bouncedActor;
}

defaultproperties
{
	bouncingMaterial=PhysicalMaterial'Heist_PhysMats.Meshes.PhysMat_PoliceDoughnut'
	bounceSound=SoundCue'Goat_Sounds.Cue.Effect_bouncy_castle_bounce_1'
}